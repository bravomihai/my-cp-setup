import base64
import gzip
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
UNINSTALL = ROOT / "scripts" / "uninstall.bat"
TEXT = UNINSTALL.read_text(encoding="utf-8")


def label_block(start: str, end: str) -> str:
    first_marker = f"\n:{start}\n"
    end_marker = f"\n:{end}\n"
    first = TEXT.index(first_marker) + 1
    last = TEXT.index(end_marker, first) + 1
    return TEXT[first:last]


def decode_cmd_carets(value: str) -> str:
    result = []
    index = 0
    while index < len(value):
        if value[index] == "^" and index + 1 < len(value):
            result.append(value[index + 1])
            index += 2
        else:
            result.append(value[index])
            index += 1
    return "".join(result).replace("%%", "%")


def rendered_powershell(block: str, variable: str) -> str:
    pattern = re.compile(
        rf'^\s*>+\s+"%{re.escape(variable)}%"\s+echo(?:\s(.*)|\s*)$',
        re.MULTILINE,
    )
    lines = []
    for match in pattern.finditer(block):
        lines.append(decode_cmd_carets(match.group(1) or ""))
    if not lines:
        raise AssertionError(f"No generated PowerShell found for {variable}")
    return "\r\n".join(lines)


def embedded_block(name: str) -> str:
    lines = TEXT.splitlines()
    first = lines.index(f"::{name}_BEGIN__")
    last = lines.index(f"::{name}_END__")
    payload = lines[first + 1 : last]
    if not all(line.startswith("::") for line in payload):
        raise AssertionError(f"Malformed embedded PowerShell block: {name}")
    return "\r\n".join(line[2:] for line in payload)


def assert_powershell_parses(test: unittest.TestCase, source: str) -> None:
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", suffix=".ps1", delete=False
    ) as stream:
        stream.write(source)
        path = Path(stream.name)
    try:
        escaped_path = str(path).replace("'", "''")
        command = (
            "$ErrorActionPreference='Stop';"
            f"$source=[IO.File]::ReadAllText('{escaped_path}');"
            "[void][scriptblock]::Create($source)"
        )
        result = subprocess.run(
            [
                r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
                "-NoLogo",
                "-NoProfile",
                "-NonInteractive",
                "-Command",
                command,
            ],
            capture_output=True,
            text=True,
            timeout=20,
            check=False,
        )
        test.assertEqual(0, result.returncode, result.stderr or result.stdout)
    finally:
        path.unlink(missing_ok=True)


class UninstallContractTests(unittest.TestCase):
    def test_entry_wrapper_propagates_the_real_exit_code(self) -> None:
        wrapper = TEXT[: TEXT.index(":cp_uninstall_entry_active")]
        self.assertIn('call "%~f0" %*', wrapper)
        self.assertIn('set "CP_UNINSTALL_ENTRY_EXIT=%ERRORLEVEL%"', wrapper)
        self.assertIn("exit /b %CP_UNINSTALL_ENTRY_EXIT%", wrapper)

    def test_all_embedded_powershell_blocks_parse(self) -> None:
        names = re.findall(r"(?m)^::(__CP_[A-Z0-9_]+)_BEGIN__$", TEXT)
        self.assertIn("__CP_NATIVE_ARTIFACTS", names)
        native_blocks = {
            "__CP_MEDIUM_NATIVE",
            "__CP_PROCESS_TREE_NATIVE",
            "__CP_SOURCE_LOCK_NATIVE",
        }
        for name in names:
            if name in native_blocks:
                continue
            with self.subTest(block=name):
                assert_powershell_parses(self, embedded_block(name))

    def test_embedded_native_csharp_blocks_compile(self) -> None:
        for name in (
            "__CP_MEDIUM_NATIVE",
            "__CP_PROCESS_TREE_NATIVE",
            "__CP_SOURCE_LOCK_NATIVE",
        ):
            with self.subTest(block=name):
                result = subprocess.run(
                    [
                        r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
                        "-NoLogo",
                        "-NoProfile",
                        "-NonInteractive",
                        "-Command",
                        "$s=[Console]::In.ReadToEnd();"
                        "Add-Type -TypeDefinition $s -Language CSharp "
                        "-ErrorAction Stop|Out-Null",
                    ],
                    input=embedded_block(name),
                    capture_output=True,
                    text=True,
                    timeout=45,
                    check=False,
                )
                self.assertEqual(0, result.returncode, result.stderr or result.stdout)

    def test_automation_is_opt_in_and_no_readkey_wait_remains(self) -> None:
        self.assertIn('if /i "%~1"=="--non-interactive"', TEXT)
        self.assertIn('if /i "%~1"=="--no-pause"', TEXT)
        self.assertIn('if /i "%~1"=="--log"', TEXT)
        wait = label_block("wait_to_finish", "enable_ansi")
        self.assertNotIn("pause", wait.lower())
        self.assertNotIn("Press any key", TEXT)
        ensure = label_block("ensure_admin", "initialize_secure_runtime")
        self.assertLess(
            ensure.index('if "%NON_INTERACTIVE%"=="1"'),
            ensure.index("::__CP_UNINSTALL_ELEVATE_BEGIN__")
            if "::__CP_UNINSTALL_ELEVATE_BEGIN__" in ensure
            else len(ensure),
        )
        self.assertIn(
            "Non-interactive uninstall requires an already elevated terminal", ensure
        )

    def test_vtl_path_and_autorun_use_exact_ownership(self) -> None:
        ansi = label_block("enable_ansi", "refresh_path")
        self.assertIn("SetConsoleMode", ansi)
        self.assertNotRegex(ansi.lower(), r"\breg(?:_exe)?%?\"?\s+add\b")
        cleanup = label_block(
            "remove_setup_configuration", "remove_external_components"
        )
        for name in (
            "Path.HadValue",
            "AutoRun.Entry",
            "Console.VirtualTerminal.Before.Kind",
            "Console.VirtualTerminal.Written",
            "Console.VirtualTerminal.Written.Kind",
        ):
            self.assertIn(name, cleanup)
        self.assertIn("$current.Value -eq [int64]$consoleWritten.Value", cleanup)
        self.assertIn(
            "$current.Exists -and [string]$current.Value -ceq [string]$pathWritten.Value",
            cleanup,
        )
        self.assertIn("$owned -inotcontains", cleanup)
        self.assertIn(
            "$current.Exists -and [string]$current.Value -ceq [string]$autoWritten.Value",
            cleanup,
        )
        self.assertIn("[StringComparison]::OrdinalIgnoreCase", cleanup)
        self.assertIn("$leftOk", cleanup)
        self.assertIn("$rightOk", cleanup)
        assert_powershell_parses(
            self, rendered_powershell(cleanup, "CONFIG_CLEANUP_PS")
        )

    def test_user_changes_after_install_are_preserved_surgically(self) -> None:
        # Mirrors the contract enforced by CONFIG_CLEANUP_PS: entries owned by
        # setup are removed while unrelated entries and commands stay intact.
        owned_paths = {r"c:\cp\scripts", r"c:\tools\g++\bin"}
        current_paths = [r"C:\User\bin", r"C:\CP\scripts", r"D:\Custom"]
        kept_paths = [
            value
            for value in current_paths
            if value.rstrip("\\").casefold()
            not in {value.rstrip("\\").casefold() for value in owned_paths}
        ]
        self.assertEqual(kept_paths, [r"C:\User\bin", r"D:\Custom"])

        owned_autorun = r'doskey /macrofile="C:\cp\scripts\cp_macros"'
        current_autorun = "user-before & " + owned_autorun + " & user-after"
        kept_autorun = current_autorun.replace(" & " + owned_autorun, "", 1)
        self.assertEqual(kept_autorun, "user-before & user-after")

    def test_only_the_atomically_marked_setup_operation_is_stopped(self) -> None:
        block = label_block("stop_setup_active_operation", "remove_created_artifacts")
        for token in (
            "Active.Operation.Intent",
            "v1",
            "Hash-Bytes",
            "CP_SETUP_TARGET_SID",
            "RunnerImagePath" if "RunnerImagePath" in block else "Get-FileHash",
            "Stop-VerifiedProcessTree",
            "Setup active-operation process is still running",
        ):
            self.assertIn(token, block)
        self.assertNotIn("Get-CimInstance", block)
        self.assertNotIn("GetProcessesByName", block)
        self.assertNotRegex(block, r"(?i)taskkill|GetProcessesByName|nvim\.exe")
        assert_powershell_parses(self, rendered_powershell(block, "ACTIVE_STOP_PS"))

    def test_artifact_cleanup_is_owned_allowlisted_and_no_follow(self) -> None:
        block = label_block("remove_created_artifacts", "clear_empty_state")
        for token in (
            "Artifacts.Before.Paths",
            "Artifacts.Created.Paths",
            "RegistryValueKind]::MultiString",
            "Join-Path $artifactLocal 'Temp'",
            "Join-Path $artifactLocal 'cache'",
            "Assert-NoReparsePath",
            "cp_setup_*.log",
            "$before -icontains $full",
        ):
            self.assertIn(token, block)
        self.assertIn("call :commit_state_metadata", block)
        self.assertIn("Artifacts.Created.Paths;Artifacts.Before.Paths", block)
        assert_powershell_parses(
            self, rendered_powershell(block, "ARTIFACT_CLEANUP_PS")
        )

    def test_elevation_has_transcript_timeouts_and_deterministic_exit(self) -> None:
        for token in (
            "UNINSTALL_UAC_TIMEOUT_SECONDS=300",
            "UNINSTALL_CHILD_TIMEOUT_SECONDS=7200",
            "cp_setup_uninstall.log",
            "[CP-SETUP] START timestamp=",
            "[CP-SETUP] CHILD pid=",
            "[CP-SETUP] END timestamp=",
            "exit [int]$process.ExitCode",
            "Stop-ElevatedTree",
            "Stop-HelperTree",
            "CpSetup.Native.ProcessTree",
            "exit 124",
        ):
            self.assertIn(token, TEXT)
        self.assertNotIn("$p.WaitForExit()", TEXT)
        self.assertNotIn("Start-Job", TEXT)
        self.assertNotIn("Receive-Job", TEXT)
        self.assertNotIn("Get-CimInstance", TEXT)
        self.assertNotIn("Start-Process -FilePath $Taskkill", TEXT)
        lines = TEXT.splitlines()
        for begin, end in (
            ("::__CP_UNINSTALL_ELEVATE_BEGIN__", "::__CP_UNINSTALL_ELEVATE_END__"),
            ("::__CP_UNINSTALL_CHILD_BEGIN__", "::__CP_UNINSTALL_CHILD_END__"),
        ):
            first = lines.index(begin)
            last = lines.index(end)
            source = "\r\n".join(line[2:] for line in lines[first + 1 : last])
            assert_powershell_parses(self, source)

        elevate = "\n".join(
            line[2:]
            for line in lines[
                lines.index("::__CP_UNINSTALL_ELEVATE_BEGIN__") + 1 : lines.index(
                    "::__CP_UNINSTALL_ELEVATE_END__"
                )
            ]
        )
        cancellation = elevate.index("canceled|cancelled|denied|1223")
        self.assertIn(
            "Join-Path $env:CP_VISIBLE_TEMP 'cp_setup_uninstall.log'", elevate
        )
        generic = elevate.index(
            "Uninstall failed while requesting administrator rights"
        )
        self.assertLess(cancellation, generic)
        self.assertRegex(
            elevate[cancellation:generic], r"Uninstall canceled by user\.[^\n]*exit 1"
        )
        self.assertIn("$finalExit=$childExit", elevate)
        self.assertIn("if($finalExit-eq10)", elevate)
        self.assertIn("if($code-eq1223)", elevate)
        self.assertIn(
            "Ok=$false;ExitCode=1;Details='UAC canceled or denied (1223).'", elevate
        )
        self.assertIn("Elevation failed before child start.", elevate)
        self.assertIn(
            "$env:CP_ELEVATE_WINDOW_STYLE=if($isCheck-or$tokens-contains'--non-interactive'){'Hidden'}else{'Normal'}",
            elevate,
        )
        self.assertIn("$windowStyle-notin@('Hidden','Normal')", elevate)
        self.assertIn("WindowStyle=$windowStyle", elevate)

    def test_elevated_payload_keeps_command_line_headroom(self) -> None:
        payload = embedded_block("__CP_UNINSTALL_CHILD").encode("utf-8")
        packed = base64.b64encode(gzip.compress(payload, mtime=0)).decode("ascii")
        bootstrap = (
            "$ErrorActionPreference='Stop';$packed=[Convert]::FromBase64String('"
            + packed
            + "');$input=[IO.MemoryStream]::new($packed);"
            "$gzip=[IO.Compression.GzipStream]::new($input,"
            "[IO.Compression.CompressionMode]::Decompress);"
            "$reader=[IO.StreamReader]::new($gzip,[Text.Encoding]::UTF8,$true);"
            "try{$childSource=$reader.ReadToEnd()}finally{$reader.Dispose();"
            "$gzip.Dispose();$input.Dispose()};&([scriptblock]::Create($childSource))"
        )
        encoded = base64.b64encode(bootstrap.encode("utf-16-le"))
        self.assertLess(len(encoded), 26000)
        self.assertIn(
            "Elevated uninstaller bootstrap exceeds the safe Windows command-line budget",
            embedded_block("__CP_UNINSTALL_ELEVATE"),
        )

    def test_component_logs_are_published_by_the_target_medium_token(self) -> None:
        publisher = label_block("publish_component_log", "commit_state_metadata")
        for token in (
            "Log publisher SID mismatch",
            "Log publisher unexpectedly has an elevated token",
            "CP_RUNTIME_TEMP",
            "CP_VISIBLE_TEMP",
            "Component log destination contains a reparse point"
            if "Component log destination contains a reparse point" in publisher
            else "Component log path contains a reparse point",
            "call :run_medium_worker",
        ):
            self.assertIn(token, publisher)
        rendered = rendered_powershell(publisher, "LOG_PUBLISHER_PS")
        self.assertIn("Flush($true)", rendered)
        self.assertIn("[IO.File]::Move", rendered)
        assert_powershell_parses(self, rendered)

        for variable, name in (
            ("CONFIG_CLEANUP_LOG", "cp_setup_config_cleanup.log"),
            ("PENDING_ACL_LOG", "cp_setup_pending_acl.log"),
            ("PENDING_COMPONENT_LOG", "cp_setup_pending_components.log"),
            ("PENDING_MASON_LOG", "cp_setup_pending_mason.log"),
            ("PENDING_ARTIFACT_LOG", "cp_setup_pending_artifacts.log"),
            ("PENDING_REGISTRY_LOG", "cp_setup_pending_registry.log"),
            ("ACTIVE_STOP_LOG", "cp_setup_active_stop.log"),
            ("ARTIFACT_CLEANUP_LOG", "cp_setup_artifact_cleanup.log"),
        ):
            self.assertIn(f'set "{variable}=%CP_RUNTIME_TEMP%\\{name}"', TEXT)
            self.assertIn(f'call :publish_component_log "{name}"', TEXT)
            self.assertNotIn(f'set "{variable}=%CP_VISIBLE_TEMP%\\{name}"', TEXT)

        runtime = embedded_block("__CP_SECURE_RUNTIME")
        self.assertIn("New-Security([bool]$includeTarget)", runtime)
        self.assertIn(
            "[Security.AccessControl.FileSystemRights]::ReadAndExecute", runtime
        )
        self.assertIn(
            "$ace.FileSystemRights-ne[Security.AccessControl.FileSystemRights]::ReadAndExecute",
            runtime,
        )

    def test_transcript_summary_and_prechild_failure_log_are_bounded(self) -> None:
        elevate = embedded_block("__CP_UNINSTALL_ELEVATE")
        for token in (
            "[Collections.Generic.HashSet[string]]",
            "$plain.Length-gt512",
            "$summary.Count-ge100",
            "FOUND|KEPT|MISSING|REMOVED|UNINSTALLED",
            "Save-AuthoritativeTranscript",
            "line-notmatch'^\\[CP-SETUP\\] END",
            "Elevated uninstaller did not produce a transcript",
            "UAC canceled or denied.",
            "Elevation timed out.",
            "Elevation failed before child start.",
            "[CP-SETUP] ORCHESTRATOR ",
            "exit='+$exitCode",
        ):
            self.assertIn(token, elevate)

    def test_timeout_kills_only_validated_trees_and_rechecks_survivors(self) -> None:
        elevate_lines = TEXT.splitlines()
        first = elevate_lines.index("::__CP_UNINSTALL_ELEVATE_BEGIN__")
        last = elevate_lines.index("::__CP_UNINSTALL_ELEVATE_END__")
        elevate = "\n".join(line[2:] for line in elevate_lines[first + 1 : last])
        child_first = elevate_lines.index("::__CP_UNINSTALL_CHILD_BEGIN__")
        child_last = elevate_lines.index("::__CP_UNINSTALL_CHILD_END__")
        child = "\n".join(
            line[2:] for line in elevate_lines[child_first + 1 : child_last]
        )
        processes = label_block(
            "stop_setup_active_operation", "remove_created_artifacts"
        )

        self.assertIn("elevationNonce", elevate)
        self.assertIn("ProcessTree]::Snapshot", elevate)
        self.assertIn("ProcessTree]::Snapshot", child)
        self.assertIn("$process.WaitForExit(1000)", child)
        helper = embedded_block("__CP_PROCESS_TREE_PS")
        self.assertIn("Process-tree survivors", helper)
        self.assertIn("Setup active-operation process is still running", processes)
        self.assertNotRegex(
            elevate + child + processes, r"(?i)taskkill|Get-CimInstance"
        )

    def test_timeout_exit_is_captured_before_cleanup_and_propagated(self) -> None:
        self.assertIn('set "UNINSTALL_TIMEOUT_SEEN=0"', TEXT)
        cases = (
            ("run_silent_command", "load_managed_pacman_packages", "SILENT_EXIT"),
            ("winget_has_package", "find_msys2_shell", "WINGET_QUERY_RUN_EXIT"),
            ("search_command", "run_command_spinner", "SEARCH_EXIT"),
            ("run_command_spinner", "run_pacman_spinner", "SPIN_EXIT"),
            ("run_pacman_spinner", "schedule_repo_removal", "SPIN_EXIT"),
        )
        for start, end, exit_name in cases:
            block = label_block(start, end)
            capture = block.index(f'if "%{exit_name}%"=="124"')
            marker = block.index('set "UNINSTALL_TIMEOUT_SEEN=1"', capture)
            final_exit = block.rindex("exit /b")
            self.assertLess(capture, marker, start)
            self.assertLess(marker, final_exit, start)

        pacman_verify = label_block(
            "verify_pacman_packages_removed", "run_silent_command"
        )
        self.assertIn(
            'endlocal & set "UNINSTALL_TIMEOUT_SEEN=1" & exit /b 124',
            pacman_verify,
        )

        failed = label_block("failed", ":__CP_NATIVE_ARTIFACTS_BEGIN__")
        captured = failed.index('set "UNINSTALL_FAILURE_EXIT=%ERRORLEVEL%"')
        timeout_override = failed.index(
            'if "%UNINSTALL_TIMEOUT_SEEN%"=="1" set "UNINSTALL_FAILURE_EXIT=124"'
        )
        cleanup = failed.index("call :cleanup_secure_runtime")
        returned = failed.index("exit /b %UNINSTALL_FAILURE_EXIT%")
        self.assertLess(captured, timeout_override)
        self.assertLess(timeout_override, cleanup)
        self.assertLess(cleanup, returned)

    def test_generated_timeout_and_mason_scripts_parse(self) -> None:
        silent = label_block("run_silent_command", "load_managed_pacman_packages")
        mason = label_block("remove_managed_mason_packages", "ask_yes_no")
        assert_powershell_parses(self, rendered_powershell(silent, "SILENT_PS"))
        assert_powershell_parses(self, rendered_powershell(mason, "MASON_CLEANUP_PS"))
        self.assertIn("Wait-BoundedProcess", silent)
        self.assertIn(
            "Stop-VerifiedProcessTree", embedded_block("__CP_PROCESS_TREE_PS")
        )
        self.assertIn("RegistryValueKind]::MultiString", mason)

    def test_all_security_sensitive_generated_scripts_parse(self) -> None:
        generated_cases = (
            ("publish_component_log", "commit_state_metadata", "LOG_PUBLISHER_PS"),
            (
                "remove_setup_configuration",
                "remove_external_components",
                "CONFIG_CLEANUP_PS",
            ),
            ("run_silent_command", "load_managed_pacman_packages", "SILENT_PS"),
            (
                "stop_setup_active_operation",
                "remove_created_artifacts",
                "ACTIVE_STOP_PS",
            ),
            ("remove_created_artifacts", "clear_empty_state", "ARTIFACT_CLEANUP_PS"),
            (
                "remove_nvim_generated_data",
                "remove_managed_mason_packages",
                "NVIM_CLEANUP_PS",
            ),
            ("remove_managed_mason_packages", "ask_yes_no", "MASON_CLEANUP_PS"),
            ("run_command_spinner", "run_pacman_spinner", "SPIN_PS"),
            (
                "recover_pending_components",
                "recover_pending_mason",
                "PENDING_COMPONENT_READ",
            ),
            (
                "recover_pending_components",
                "recover_pending_mason",
                "PENDING_COMPONENT_COMMIT",
            ),
            (
                "recover_pending_registry",
                "stop_setup_active_operation",
                "PENDING_REGISTRY_WORKER",
            ),
            (
                "recover_pending_registry",
                "stop_setup_active_operation",
                "PENDING_REGISTRY_COMMIT",
            ),
        )
        for start, end, variable in generated_cases:
            with self.subTest(variable=variable):
                assert_powershell_parses(
                    self, rendered_powershell(label_block(start, end), variable)
                )
        for name in ("__CP_PENDING_MASON_WORKER", "__CP_PENDING_MASON_COMMIT"):
            with self.subTest(block=name):
                assert_powershell_parses(self, embedded_block(name))


if __name__ == "__main__":
    unittest.main()
