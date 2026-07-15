import ast
import base64
import ctypes
import gzip
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "scripts" / "install.bat"


def source() -> str:
    return INSTALLER.read_text(encoding="utf-8")


def block(name: str) -> str:
    lines = source().splitlines()
    begin = f"::{name}_BEGIN__"
    end = f"::{name}_END__"
    first = lines.index(begin)
    last = lines.index(end)
    payload = lines[first + 1 : last]
    if not all(line.startswith("::") for line in payload):
        raise AssertionError(f"malformed source block {name}")
    return "\n".join(line[2:] for line in payload)


def label(name: str) -> str:
    match = re.search(
        rf"(?ms)^:{re.escape(name)}\s*$\n(.*?)(?=^:[A-Za-z0-9_]+\s*$|\Z)",
        source(),
    )
    if not match:
        raise AssertionError(f"missing batch label: {name}")
    return match.group(1)


def generated_echo(block_source: str, variable: str) -> str:
    result: list[str] = []
    marker = f'"%{variable}%" echo'
    for line in block_source.splitlines():
        if marker not in line:
            continue
        payload = line.split(marker, 1)[1]
        if payload == ".":
            result.append("")
            continue
        payload = payload[1:] if payload.startswith(" ") else payload
        result.append(re.sub(r"\^(.)", r"\1", payload).replace("%%", "%"))
    if not result:
        raise AssertionError(f"no generated source for {variable}")
    return "\n".join(result) + "\n"


class InstallContractTests(unittest.TestCase):
    def test_entry_wrapper_propagates_the_real_exit_code(self) -> None:
        text = source()
        wrapper = text[: text.index(":cp_setup_entry_active")]
        self.assertIn('call "%~f0" %*', wrapper)
        self.assertIn('set "CP_SETUP_ENTRY_EXIT=%ERRORLEVEL%"', wrapper)
        self.assertIn("exit /b %CP_SETUP_ENTRY_EXIT%", wrapper)

    def test_composable_cli_is_explicit(self) -> None:
        text = source()
        for option in ("--non-interactive", "--no-pause", "--log"):
            self.assertIn(f'if /i "%~1"=="{option}"', text)
        self.assertIn(
            "Administrator rights are required in non-interactive mode.", text
        )

    def test_already_elevated_install_reenters_for_authoritative_transcript(
        self,
    ) -> None:
        text = source()
        parent = block("__CP_ELEVATE_ORCHESTRATOR")
        self.assertIn('if "%CP_SETUP_ELEVATED_CHILD%"=="1" exit /b 0', text)
        self.assertNotIn("if not defined INSTALL_LOG_REQUESTED exit /b 0", text)
        self.assertIn('set "CP_ELEVATE_ALREADY_ADMIN=1"', text)
        self.assertIn("$alreadyAdmin = $env:CP_ELEVATE_ALREADY_ADMIN -eq '1'", parent)
        self.assertIn("if($alreadyAdmin){$childArgs=", parent)
        self.assertIn("-WindowStyle Hidden", parent)
        self.assertIn("Join-Path $env:VISIBLE_TEMP 'cp_setup_install.log'", parent)
        self.assertIn("Publish-Transcript", parent)
        self.assertIn("MediumTokenRunner]::Run", parent)

    def test_elevation_contract_has_no_unbounded_wait_or_pause(self) -> None:
        parent = block("__CP_ELEVATE_ORCHESTRATOR")
        child = block("__CP_ELEVATED_CHILD")
        combined = parent + "\n" + child
        self.assertNotRegex(combined, r"(?i)ReadKey|Press any key")
        self.assertNotRegex(combined, r"(?im)^\s*pause(?:\s|$)")
        self.assertIn("$uacTimeout", parent)
        self.assertIn("$childTimeout", parent)
        self.assertNotIn("Start-Job", parent)
        self.assertNotIn("Receive-Job", parent)
        self.assertIn("$p.WaitForExit($limit*1000)", parent)
        self.assertIn("$helper.WaitForExit(5000)", parent)
        self.assertIn("$exitCode=124", child)
        self.assertIn("taskkill.exe", child)
        self.assertNotIn(".WaitForExit()", combined)

    def test_elevated_payload_keeps_command_line_headroom(self) -> None:
        payload = block("__CP_ELEVATED_CHILD").encode("utf-8")
        packed = base64.b64encode(gzip.compress(payload, mtime=0)).decode("ascii")
        bootstrap = (
            "$raw=[Convert]::FromBase64String('"
            + packed
            + "');$memory=[IO.MemoryStream]::new(,$raw);"
            "$gzip=[IO.Compression.GzipStream]::new($memory,"
            "[IO.Compression.CompressionMode]::Decompress);"
            "$reader=[IO.StreamReader]::new($gzip,[Text.Encoding]::UTF8);"
            "try{$source=$reader.ReadToEnd()}finally{$reader.Dispose();"
            "$gzip.Dispose();$memory.Dispose()};&([scriptblock]::Create($source))"
        )
        encoded = base64.b64encode(bootstrap.encode("utf-16-le"))
        self.assertLess(len(encoded), 26000)
        self.assertIn(
            "Elevated bootstrap exceeds the safe Windows command-line budget",
            block("__CP_ELEVATE_ORCHESTRATOR"),
        )

    def test_timeout_requests_child_cleanup_and_has_a_validated_tree_kill(self) -> None:
        parent = block("__CP_ELEVATE_ORCHESTRATOR")
        child = block("__CP_ELEVATED_CHILD")
        self.assertIn("CP_ELEVATE_CANCEL_FILE", parent)
        self.assertIn("Get-ValidatedElevatedProcess", parent)
        self.assertIn("Stop-ElevatedTree $startedFile", parent)
        self.assertIn("$process.SessionId", parent)
        self.assertIn("$process.StartTime.ToUniversalTime()", parent)
        self.assertIn("[IO.File]::Exists($cancelFile)", child)
        self.assertIn("Join-Path $dir 'cancel.marker'", child)
        self.assertIn("Stop-Tree $process $system32", child)
        self.assertIn("@('/PID',[string]$process.Id,'/T','/F')", parent)
        self.assertIn("$killer.WaitForExit(10000)", parent)
        self.assertIn("@('/PID',[string]$process.Id,'/T','/F')", child)
        self.assertIn("$process.WaitForExit(5000)", child)
        self.assertNotRegex(
            parent + child, r"(?i)(?:/IM|GetProcessesByName)\s+.*powershell"
        )

    def test_uac_cancel_deny_and_child_exit_codes_are_deterministic(self) -> None:
        parent = block("__CP_ELEVATE_ORCHESTRATOR")
        cancellation = parent.index("canceled|cancelled|denied|1223")
        generic_failure = parent.index(
            "Install failed while requesting administrator rights"
        )
        self.assertLess(cancellation, generic_failure)
        self.assertRegex(
            parent[cancellation:generic_failure],
            r"Install canceled by user\.[^\n]*exit 1",
        )
        self.assertIn("if($childExit -eq 124)", parent)
        self.assertIn("exit 124", parent)
        self.assertIn("exit $childExit", parent)

    def test_transcript_and_exit_are_parent_authoritative(self) -> None:
        parent = block("__CP_ELEVATE_ORCHESTRATOR")
        child = block("__CP_ELEVATED_CHILD")
        self.assertIn("Publish-Transcript", parent)
        self.assertIn("MediumTokenRunner]::Run", parent)
        self.assertIn("Get-TranscriptSummary", parent)
        self.assertIn("foreach ($line in $summary)", parent)
        self.assertIn("$Matches[1]+$reset", parent)
        self.assertIn("Install completed (see README for more info)", parent)
        self.assertIn("exit $childExit", parent)
        self.assertIn("[CP-SETUP] START", child)
        self.assertIn("[CP-SETUP] CHILD pid=", child)
        self.assertIn("[CP-SETUP] END", child)
        self.assertIn("ReadAndExecute", child)
        self.assertIn(
            "ReadAndExecute-bor[Security.AccessControl.FileSystemRights]::Delete", child
        )
        self.assertIn("SetAccessRuleProtection($true,$false)", child)
        self.assertNotRegex(
            child,
            r"targetRights=.*(?:Write|Modify|FullControl|ChangePermissions|TakeOwnership)",
        )

    def test_transcript_summary_and_prechild_failure_log_are_bounded(self) -> None:
        parent = block("__CP_ELEVATE_ORCHESTRATOR")
        for token in (
            "[Collections.Generic.HashSet[string]]",
            "$plain.Length -gt 512",
            "$summary.Count -ge 100",
            "FOUND|INSTALLED|UPDATED|UP TO DATE",
            "elseif($hadElevatedChild)",
            "Elevated installer did not produce a transcript",
            "$authoritativeExit=if($timedOut",
            "UAC canceled or denied.",
            "Elevation timed out.",
            "Elevation failed before child start.",
            "[CP-SETUP] ORCHESTRATOR ",
            "CP_TRANSCRIPT_EXIT",
        ):
            self.assertIn(token, parent)

    def test_lazy_and_mason_are_medium_token_workers(self) -> None:
        text = source()
        self.assertRegex(
            text,
            r'call :create_nvim_medium_worker "lazy"[\s\S]+?'
            r'call :run_install_spinner "LazyVim plugins"',
        )
        self.assertRegex(
            text,
            r'call :create_nvim_medium_worker "mason"[\s\S]+?'
            r'call :run_install_spinner "Neovim language tools"',
        )
        native = block("__CP_MEDIUM_NATIVE")
        self.assertIn("CreateProcessWithTokenW", native)
        self.assertIn("CREATE_SUSPENDED", native)
        self.assertIn("AssignProcessToJobObject", native)

    def test_user_scoped_ownership_uses_the_original_standard_token(self) -> None:
        vtl = label("write_target_virtual_terminal")
        self.assertIn('call :run_target_registry_transaction "VTL"', vtl)

        # User registry mutations are planned by the administrator, then
        # applied under the original medium-integrity user token.
        for name, mode in (
            ("install_paths", "Path"),
            ("write_target_environment", "Environment"),
            ("install_cmd_macros", "AutoRun"),
        ):
            registry_write = label(name)
            self.assertIn(
                f'call :run_target_registry_transaction "{mode}"', registry_write
            )
        transaction = label("run_target_registry_transaction")
        self.assertIn("MEDIUM_REGISTRY_PLAN_PS", transaction)
        self.assertIn("MEDIUM_LAUNCHER_PS", transaction)
        self.assertIn("CP_SETUP_TARGET_SID", transaction)
        registry = block("__CP_USER_REGISTRY_PLAN")
        self.assertIn("Registry worker SID mismatch", registry)
        self.assertIn("Registry worker unexpectedly has an elevated token", registry)
        self.assertIn("[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey", registry)

    def test_medium_native_runner_rejects_wrong_or_elevated_tokens(self) -> None:
        native = block("__CP_MEDIUM_NATIVE")
        for token in (
            "TokenSid(token),sid",
            "TokenSessionId",
            "TokenElevation)!=0",
            "TokenElevationType)==2",
            "rid>=0x2000&&rid<0x3000",
            'Process.GetProcessesByName("explorer")',
            "CreateEnvironmentBlock",
            "JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE",
            "TerminateJobObject(job,124)",
        ):
            self.assertIn(token, native)
        self.assertLess(
            native.index("AssignProcessToJobObject"),
            native.index("ResumeThread(child.hThread)"),
        )

        registry = block("__CP_USER_REGISTRY_PLAN")
        for token in (
            "Registry worker SID mismatch",
            "Registry worker unexpectedly has an elevated token",
            "[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey",
            "Concurrent target registry change",
            "$rollbackMutations",
            "Target registry write did not verify",
        ):
            self.assertIn(token, registry)

    def test_mason_spinner_is_width_bounded(self) -> None:
        text = source()
        self.assertIn("[Console]::BufferWidth", text)
        self.assertIn("function Fit-Line", text)
        self.assertIn(r"[^\x00-\x1f\x7f]{1,160}", text)

        def shorten(value: str, limit: int) -> str:
            if not value or limit < 4:
                return ""
            return value if len(value) <= limit else value[: limit - 3] + "..."

        for width in (20, 30, 40, 80):
            status = "INSTALLING"
            fixed = len(status) + 5
            name = shorten("Neovim language tools", max(4, width - 1 - fixed))
            detail_budget = width - 1 - fixed - len(name) - 3
            detail = (
                shorten("4/4 google-java-format repairing stale links", detail_budget)
                if detail_budget >= 8
                else ""
            )
            visible = f"[{status}] \\ {name}"
            if detail:
                visible += f" ({detail})"
            self.assertLessEqual(len(visible), width - 1)

    def test_generated_verification_spinner_has_timeout_and_tree_cleanup(self) -> None:
        spinner_label = label("ensure_spinner")
        spinner = generated_echo(spinner_label, "SPINNER_PY")
        ast.parse(spinner)
        for token in (
            "timeout",
            "time.monotonic",
            "taskkill",
            '"/PID"',
            '"/T"',
            '"/F"',
            "return 124",
        ):
            self.assertIn(token, spinner)
        self.assertRegex(spinner, r"process\.(?:wait|communicate)\(timeout=")
        self.assertNotIn("while process.poll() is None:\n", spinner)

    def test_verification_spinner_timeout_kills_its_process_tree(self) -> None:
        if os.name != "nt":
            self.skipTest("process-tree contract is Windows-specific")
        spinner = generated_echo(label("ensure_spinner"), "SPINNER_PY")

        kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
        kernel32.OpenProcess.argtypes = [ctypes.c_uint32, ctypes.c_int, ctypes.c_uint32]
        kernel32.OpenProcess.restype = ctypes.c_void_p
        kernel32.GetExitCodeProcess.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_uint32),
        ]
        kernel32.GetExitCodeProcess.restype = ctypes.c_int
        kernel32.CloseHandle.argtypes = [ctypes.c_void_p]
        kernel32.CloseHandle.restype = ctypes.c_int

        def active(process_id: int) -> bool:
            handle = kernel32.OpenProcess(0x1000, False, process_id)
            if not handle:
                return False
            try:
                exit_code = ctypes.c_uint32()
                return (
                    bool(kernel32.GetExitCodeProcess(handle, ctypes.byref(exit_code)))
                    and exit_code.value == 259
                )
            finally:
                kernel32.CloseHandle(handle)

        with tempfile.TemporaryDirectory(prefix="cp_spinner_timeout_") as temporary:
            root = Path(temporary)
            spinner_path = root / "spinner.py"
            parent_path = root / "unique_parent.py"
            grandchild_path = root / "unique_grandchild.py"
            pid_path = root / "tree.pids"
            spinner_path.write_text(spinner, encoding="utf-8")
            grandchild_path.write_text(
                "import os, pathlib, sys, time\n"
                "pathlib.Path(sys.argv[1]).write_text(str(os.getpid()), encoding='ascii')\n"
                "time.sleep(30)\n",
                encoding="utf-8",
            )
            parent_path.write_text(
                "import os, pathlib, subprocess, sys, time\n"
                "child = subprocess.Popen([sys.executable, sys.argv[1], sys.argv[3]])\n"
                "pathlib.Path(sys.argv[2]).write_text(str(os.getpid()) + ',' + str(child.pid), encoding='ascii')\n"
                "time.sleep(30)\n",
                encoding="utf-8",
            )

            command = [
                sys.executable,
                str(spinner_path),
                "--label",
                "timeout-contract",
                "--cwd",
                str(ROOT),
                "--stdin-empty",
                "--timeout",
                "0.3",
                "--",
                sys.executable,
                str(parent_path),
                str(grandchild_path),
                str(pid_path),
                str(root / "grandchild.pid"),
            ]
            started = time.monotonic()
            result = subprocess.run(
                command,
                text=True,
                capture_output=True,
                timeout=15,
                check=False,
            )
            elapsed = time.monotonic() - started

            pids: list[int] = []
            if pid_path.is_file():
                pids = [
                    int(value)
                    for value in pid_path.read_text(encoding="ascii").split(",")
                ]
            try:
                self.assertEqual(result.returncode, 124, result.stdout + result.stderr)
                self.assertLess(elapsed, 10)
                self.assertEqual(len(pids), 2, "the unique process tree did not start")
                deadline = time.monotonic() + 2
                while any(active(pid) for pid in pids) and time.monotonic() < deadline:
                    time.sleep(0.05)
                self.assertFalse(
                    any(active(pid) for pid in pids),
                    f"verification spinner left survivors: {pids}",
                )
            finally:
                taskkill = (
                    Path(os.environ.get("SystemRoot", r"C:\Windows"))
                    / "System32"
                    / "taskkill.exe"
                )
                for pid in pids:
                    if active(pid):
                        try:
                            subprocess.run(
                                [str(taskkill), "/PID", str(pid), "/T", "/F"],
                                stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL,
                                timeout=5,
                                check=False,
                            )
                        except (OSError, subprocess.TimeoutExpired):
                            pass
                cleanup_deadline = time.monotonic() + 6
                while (
                    any(active(pid) for pid in pids)
                    and time.monotonic() < cleanup_deadline
                ):
                    time.sleep(0.05)

    def test_silent_probe_timeout_kills_its_process_tree(self) -> None:
        if os.name != "nt":
            self.skipTest("process-tree contract is Windows-specific")
        powershell = shutil.which("powershell")
        if not powershell:
            self.skipTest("Windows PowerShell is unavailable")

        silent_script = generated_echo(label("run_silent_timeout"), "SILENT_PS")
        kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
        kernel32.OpenProcess.argtypes = [ctypes.c_uint32, ctypes.c_int, ctypes.c_uint32]
        kernel32.OpenProcess.restype = ctypes.c_void_p
        kernel32.GetExitCodeProcess.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_uint32),
        ]
        kernel32.GetExitCodeProcess.restype = ctypes.c_int
        kernel32.CloseHandle.argtypes = [ctypes.c_void_p]
        kernel32.CloseHandle.restype = ctypes.c_int

        def active(process_id: int) -> bool:
            handle = kernel32.OpenProcess(0x1000, False, process_id)
            if not handle:
                return False
            try:
                exit_code = ctypes.c_uint32()
                return (
                    bool(kernel32.GetExitCodeProcess(handle, ctypes.byref(exit_code)))
                    and exit_code.value == 259
                )
            finally:
                kernel32.CloseHandle(handle)

        with tempfile.TemporaryDirectory(
            prefix="cp_silent_timeout_", ignore_cleanup_errors=True
        ) as temporary:
            root = Path(temporary)
            silent_path = root / "silent.ps1"
            parent_path = root / "parent.py"
            grandchild_path = root / "grandchild.py"
            pid_path = root / "tree.pids"
            silent_path.write_text(silent_script, encoding="utf-8")
            grandchild_path.write_text(
                "import time\ntime.sleep(30)\n",
                encoding="utf-8",
            )
            parent_path.write_text(
                "import os, pathlib, subprocess, sys, time\n"
                "child = subprocess.Popen([sys.executable, sys.argv[1]])\n"
                "pathlib.Path(sys.argv[2]).write_text(str(os.getpid()) + ',' + str(child.pid), encoding='ascii')\n"
                "time.sleep(30)\n",
                encoding="utf-8",
            )

            environment = os.environ.copy()
            environment.update(
                {
                    "SILENT_COMMAND": subprocess.list2cmdline(
                        [
                            sys.executable,
                            str(parent_path),
                            str(grandchild_path),
                            str(pid_path),
                        ]
                    ),
                    "SILENT_STDOUT": str(root / "stdout.txt"),
                    "SILENT_STDERR": str(root / "stderr.txt"),
                    "SILENT_TIMEOUT_SECONDS": "1",
                    "EXEC_TEMP": str(root),
                    "CMD_EXE": str(
                        Path(os.environ.get("SystemRoot", r"C:\Windows"))
                        / "System32"
                        / "cmd.exe"
                    ),
                    "TASKKILL_EXE": str(
                        Path(os.environ.get("SystemRoot", r"C:\Windows"))
                        / "System32"
                        / "taskkill.exe"
                    ),
                }
            )
            started = time.monotonic()
            result = subprocess.run(
                [
                    powershell,
                    "-NoLogo",
                    "-NoProfile",
                    "-NonInteractive",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(silent_path),
                ],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
                timeout=15,
                check=False,
            )
            elapsed = time.monotonic() - started

            pids: list[int] = []
            if pid_path.is_file():
                pids = [
                    int(value)
                    for value in pid_path.read_text(encoding="ascii").split(",")
                ]
            try:
                self.assertEqual(result.returncode, 124, result.stdout + result.stderr)
                self.assertLess(elapsed, 10)
                self.assertEqual(
                    len(pids), 2, "the silent probe process tree did not start"
                )
                deadline = time.monotonic() + 2
                while any(active(pid) for pid in pids) and time.monotonic() < deadline:
                    time.sleep(0.05)
                self.assertFalse(
                    any(active(pid) for pid in pids),
                    f"silent probe left survivors: {pids}",
                )
            finally:
                taskkill = Path(environment["TASKKILL_EXE"])
                for pid in pids:
                    if active(pid):
                        subprocess.run(
                            [str(taskkill), "/PID", str(pid), "/T", "/F"],
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL,
                            timeout=5,
                            check=False,
                        )
                cleanup_deadline = time.monotonic() + 6
                while (
                    any(active(pid) for pid in pids)
                    and time.monotonic() < cleanup_deadline
                ):
                    time.sleep(0.05)

    def test_verify_and_ac_library_do_not_run_unbounded_external_probes(self) -> None:
        for finder in ("find_git", "find_nvim_011", "find_ruff"):
            self.assertIn("call :run_tool_finder", label(finder))
        search = label("search_command")
        self.assertIn("$started.Elapsed.TotalSeconds -ge 120", search)
        self.assertIn("call :prepare_process_tree_helper", search)
        self.assertIn("Stop-CpProcessTree $process $env:TASKKILL_EXE", search)
        self.assertIn("Process-tree survivor", label("prepare_process_tree_helper"))

        silent = label("run_silent_timeout")
        self.assertNotRegex(silent, r"(?i)Get-(?:CimInstance|WmiObject)")
        rendered_silent = generated_echo(silent, "SILENT_PS")
        native_match = re.search(r"FromBase64String\('([^']+)'\)", rendered_silent)
        self.assertIsNotNone(native_match, "missing native process-tree payload")
        native = base64.b64decode(native_match.group(1)).decode("utf-8")
        self.assertIn("CreateToolhelp32Snapshot", native)
        self.assertIn("Process32First", native)
        self.assertIn("Process32Next", native)
        self.assertIn("Process-tree survivor", silent)

        verify = label("verify")
        self.assertNotIn('echo. | "%FOUND_RUFF_PATH%" check', verify)
        self.assertNotRegex(
            verify,
            r'(?im)^\s*(?:"%FOUND_GIT_PATH%"|git)\s+.*submodule\s+status',
        )
        self.assertIn("call :run_silent_timeout", verify)

        ac_check = label("ac_library_needs_update")
        unbounded_git = [
            line
            for line in ac_check.splitlines()
            if re.match(r'^\s*(?:"%FOUND_GIT_PATH%"|git)\s+', line, re.IGNORECASE)
        ]
        self.assertEqual(
            unbounded_git,
            [],
            "ac-library inspection must use bounded process helpers",
        )
        self.assertIn("call :run_silent_timeout", ac_check)

    def test_search_results_stay_an_array_when_only_one_path_is_found(self) -> None:
        search = generated_echo(label("search_command"), "SEARCH_PS")
        self.assertIn("$items = @(if (Test-Path -LiteralPath $output)", search)
        self.assertNotIn("$items = if (Test-Path -LiteralPath $output)", search)

    def test_ac_library_gitlink_parser_reads_and_validates_ls_tree_output(
        self,
    ) -> None:
        ac_check = label("ac_library_needs_update")
        self.assertIn(
            'for /F "usebackq tokens=1,2,3,*" %%A in ("%AC_GIT_OUTPUT%")',
            ac_check,
        )
        self.assertIn('if not "!AC_LIBRARY_ENTRY_MODE!"=="160000"', ac_check)
        self.assertIn('if /i not "!AC_LIBRARY_ENTRY_TYPE!"=="commit"', ac_check)
        self.assertIn(
            'if /i not "!AC_LIBRARY_ENTRY_PATH!"=="libraries/ac-library"',
            ac_check,
        )

    def test_all_embedded_powershell_blocks_parse(self) -> None:
        powershell = shutil.which("powershell")
        if not powershell:
            self.skipTest("Windows PowerShell is unavailable")
        names = re.findall(r"(?m)^::(__CP_[A-Z0-9_]+)_BEGIN__$", source())
        self.assertIn("__CP_MEDIUM_LAUNCHER", names)
        scripts = [
            (name, block(name)) for name in names if name != "__CP_MEDIUM_NATIVE"
        ]
        scripts.append(
            (
                "generated run_silent_timeout",
                generated_echo(label("run_silent_timeout"), "SILENT_PS"),
            )
        )
        for name, script in scripts:
            encoded = subprocess.run(
                [
                    powershell,
                    "-NoLogo",
                    "-NoProfile",
                    "-NonInteractive",
                    "-Command",
                    "$s=[Console]::In.ReadToEnd();$t=$null;$e=$null;"
                    "[Management.Automation.Language.Parser]::ParseInput("
                    "$s,[ref]$t,[ref]$e)|Out-Null;"
                    "if($e.Count){$e|ForEach-Object ToString;exit 1}",
                ],
                input=script,
                text=True,
                capture_output=True,
                timeout=15,
                check=False,
            )
            self.assertEqual(
                encoded.returncode,
                0,
                f"{name}: {encoded.stdout}{encoded.stderr}",
            )

    def test_embedded_medium_native_csharp_compiles(self) -> None:
        powershell = shutil.which("powershell")
        if not powershell:
            self.skipTest("Windows PowerShell is unavailable")
        result = subprocess.run(
            [
                powershell,
                "-NoLogo",
                "-NoProfile",
                "-NonInteractive",
                "-Command",
                "$s=[Console]::In.ReadToEnd();"
                "Add-Type -TypeDefinition $s -Language CSharp -ErrorAction Stop|Out-Null",
            ],
            input=block("__CP_MEDIUM_NATIVE"),
            text=True,
            capture_output=True,
            timeout=45,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
