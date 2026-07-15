import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INSTALL = ROOT / "scripts" / "install.bat"
UNINSTALL = ROOT / "scripts" / "uninstall.bat"


def label_block(source: str, label: str) -> str:
    match = re.search(
        rf"(?ms)^:{re.escape(label)}\s*$\n(.*?)(?=^:[A-Za-z0-9_]+\s*$|\Z)",
        source,
    )
    if not match:
        raise AssertionError(f"missing batch label: {label}")
    return match.group(1)


def decode_cmd_carets(value: str) -> str:
    decoded: list[str] = []
    index = 0
    while index < len(value):
        if value[index] == "^" and index + 1 < len(value):
            index += 1
        decoded.append(value[index])
        index += 1
    return "".join(decoded).replace("%%", "%")


def generated_powershell(block: str, variable: str) -> str:
    lines: list[str] = []
    marker = f'"%{variable}%" echo'
    for batch_line in block.splitlines():
        if marker not in batch_line:
            continue
        payload = batch_line.split(marker, 1)[1]
        if payload == ".":
            lines.append("")
        elif payload.startswith(" "):
            lines.append(decode_cmd_carets(payload[1:]))
        else:
            lines.append(decode_cmd_carets(payload))
    if not lines:
        raise AssertionError(f"no generated PowerShell for {variable}")
    return ("\n".join(lines) + "\n").replace("%STATE_SCHEMA%", "5")


class InstallerNeovimStateTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.install = INSTALL.read_text(encoding="utf-8")
        cls.uninstall = UNINSTALL.read_text(encoding="utf-8")

    def test_neovim_snapshot_is_written_once_before_completion(self) -> None:
        initialize = label_block(self.install, "initialize_state")
        self.assertIn(
            "if ^(@^($state.GetValueNames^(^)^) -notcontains 'Snapshot.Complete'^)",
            initialize,
        )
        snapshot = initialize.index("$state.SetValue^('NvimData.Existed'")
        mason = initialize.index("$state.SetValue^('Mason.Packages.Before'")
        jdtls = initialize.index("$state.SetValue^('JdtlsWorkspace.Existed'")
        complete = initialize.index("$state.SetValue^('Snapshot.Complete'")
        self.assertLess(snapshot, complete)
        self.assertLess(mason, complete)
        self.assertLess(jdtls, complete)

        prepare = label_block(self.install, "prepare_nvim_bootstrap")
        self.assertNotIn("SetValue^('NvimData.Existed'", prepare)
        self.assertNotIn("SetValue^('Mason.Packages.Before'", prepare)
        self.assertNotIn("SetValue^('JdtlsWorkspace.Existed'", prepare)
        self.assertIn("SetValue^('Nvim.BootstrapStarted'", prepare)
        self.assertIn("if ^($names -contains 'Nvim.BootstrapStarted'^)", prepare)
        self.assertIn("Incomplete immutable Neovim snapshot", prepare)

    def test_mason_ownership_is_the_complete_inventory_difference(self) -> None:
        record = label_block(self.install, "record_mason_packages")
        self.assertIn("Get-ChildItem -LiteralPath $root -Directory", record)
        self.assertIn("CandidatePackages", record)
        self.assertIn("ExcludedPackages", record)
        self.assertIn("$before-inotcontains$_", record)
        self.assertNotIn("$env:MASON_MISSING", record)
        self.assertNotIn("$env:MASON_TOOLS", record)
        self.assertIn("RegistryValueKind]::MultiString", record)

        cleanup = label_block(self.uninstall, "remove_managed_mason_packages")
        self.assertNotIn("$env:MASON_TOOLS", cleanup)
        self.assertNotIn("$allowed -inotcontains", cleanup)
        self.assertIn("Invalid Mason ownership inventory kind", cleanup)

        # Mason may install dependencies that were not named in the requested
        # tool list. Ownership must therefore use the full before/after delta.
        before = {name.casefold() for name in ("pyright", "jdtls")}
        after = {
            name.casefold()
            for name in ("pyright", "jdtls", "google-java-format", "tree-sitter-cli")
        }
        owned = after - before
        self.assertEqual(owned, {"google-java-format", "tree-sitter-cli"})

    def test_lazy_lockfile_is_read_locked_and_worktree_is_guarded(self) -> None:
        worker = label_block(self.install, "create_nvim_medium_worker")
        self.assertIn("nvim\\lazy-lock.json", worker)
        self.assertIn("[IO.FileShare]::Read", worker)
        self.assertIn("$lockHandle.Dispose", worker)

        bootstrap = label_block(self.install, "bootstrap_nvim_tools")
        capture = bootstrap.index("call :prepare_nvim_worktree_guard")
        lazy = bootstrap.index('call :create_nvim_medium_worker "lazy"')
        lazy_verify = bootstrap.index("call :verify_nvim_worktree_guard", lazy)
        mason_preflight = bootstrap.index("call :verify_mason_tools", lazy_verify)
        preflight_verify = bootstrap.index(
            "call :verify_nvim_worktree_guard", mason_preflight
        )
        mason = bootstrap.index('call :create_nvim_medium_worker "mason"')
        mason_verify = bootstrap.index("call :verify_nvim_worktree_guard", mason)
        mason_postflight = bootstrap.index("call :verify_mason_tools", mason_verify)
        postflight_verify = bootstrap.index(
            "call :verify_nvim_worktree_guard", mason_postflight
        )
        self.assertLess(capture, lazy)
        self.assertLess(lazy, lazy_verify)
        self.assertLess(lazy_verify, mason_preflight)
        self.assertLess(mason_preflight, preflight_verify)
        self.assertLess(preflight_verify, mason)
        self.assertLess(mason, mason_verify)
        self.assertLess(mason_verify, mason_postflight)
        self.assertLess(mason_postflight, postflight_verify)

        guard = label_block(self.install, "prepare_nvim_worktree_guard")
        self.assertIn("SHA256", guard)
        self.assertIn("$full -ieq $gitPath", guard)
        self.assertIn("Reparse point blocks worktree verification", guard)
        self.assertIn("[IO.FileAccess]::Read", guard)
        self.assertIn("[IO.FileShare]::Read", guard)
        self.assertIn("The setup worktree changed during Neovim bootstrap", guard)

        # Both headless phases and both Mason verification probes are followed
        # by a complete manifest verification.
        self.assertEqual(bootstrap.count("call :verify_nvim_worktree_guard"), 4)
        self.assertNotIn("git checkout", bootstrap.lower())
        self.assertNotIn("git reset", bootstrap.lower())

    def test_generated_state_scripts_parse_as_powershell(self) -> None:
        cases = (
            (label_block(self.install, "initialize_state"), "STATE_INIT_PS"),
            (
                label_block(self.install, "prepare_nvim_bootstrap"),
                "NVIM_STATE_PS",
            ),
            (
                label_block(self.install, "record_mason_packages"),
                "MASON_RECORD_PS",
            ),
            (
                label_block(self.install, "prepare_nvim_worktree_guard"),
                "NVIM_WORKTREE_PS",
            ),
            (
                label_block(self.install, "create_nvim_medium_worker"),
                "MEDIUM_WORKER_BUILD_PS",
            ),
            (
                label_block(self.uninstall, "remove_managed_mason_packages"),
                "MASON_CLEANUP_PS",
            ),
        )
        with tempfile.TemporaryDirectory() as temporary:
            for index, (block, variable) in enumerate(cases):
                script = Path(temporary) / f"generated-{index}.ps1"
                script.write_text(
                    generated_powershell(block, variable), encoding="utf-8"
                )
                command = (
                    "$errors=$null; "
                    f"[void][Management.Automation.Language.Parser]::ParseFile('{script}',"
                    "[ref]$null,[ref]$errors); "
                    "if($errors.Count){$errors|ForEach-Object{Write-Error $_};exit 1}"
                )
                result = subprocess.run(
                    ["powershell", "-NoProfile", "-Command", command],
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(
                    result.returncode,
                    0,
                    f"{variable} did not parse:\n{result.stdout}\n{result.stderr}\n"
                    f"{script.read_text(encoding='utf-8')}",
                )

    def test_generated_medium_worker_parses_with_lock_guard(self) -> None:
        block = label_block(self.install, "create_nvim_medium_worker")
        builder_source = generated_powershell(block, "MEDIUM_WORKER_BUILD_PS")
        powershell = shutil.which("powershell")
        self.assertIsNotNone(powershell)
        with tempfile.TemporaryDirectory() as temporary:
            builder = Path(temporary) / "builder.ps1"
            worker = Path(temporary) / "worker.ps1"
            tool_dir = Path(temporary) / "tools"
            tool_dir.mkdir()
            tools = {
                name: tool_dir / filename
                for name, filename in {
                    "FOUND_GIT_PATH": "git.exe",
                    "FOUND_NODE_PATH": "node.exe",
                    "FOUND_NPM_PATH": "npm.cmd",
                    "FOUND_NVIM_PATH": "nvim.exe",
                    "FOUND_JAVAC_PATH": "javac.exe",
                    "FOUND_JAVA_PATH": "java.exe",
                    "CP_GPP": "g++.exe",
                    "CP_PYTHON": "python.exe",
                    "FOUND_RUFF_PATH": "ruff.exe",
                }.items()
            }
            for path in tools.values():
                path.write_bytes(b"")
            builder.write_text(builder_source, encoding="utf-8")
            environment = os.environ.copy()
            environment.update(
                {
                    "ROOT": str(ROOT),
                    "CP_SETUP_TARGET_SID": "S-1-5-21-1-2-3-1001",
                    "CP_SETUP_TARGET_LOCALAPPDATA": str(Path(temporary) / "Local"),
                    "MEDIUM_WORKER_MODE": "lazy",
                    "MEDIUM_WORKER_INPUT": "",
                    "MEDIUM_WORKER_PS": str(worker),
                    "POWERSHELL_EXE": str(powershell),
                    "SYSTEM32_DIR": str(Path(os.environ["SystemRoot"]) / "System32"),
                    "CP_JAVAC": str(tools["FOUND_JAVAC_PATH"]),
                    "CP_JAVA": str(tools["FOUND_JAVA_PATH"]),
                    **{name: str(path) for name, path in tools.items()},
                }
            )
            built = subprocess.run(
                [
                    powershell,
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(builder),
                ],
                env=environment,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(built.returncode, 0, built.stderr)
            self.assertTrue(worker.is_file())
            command = (
                "$errors=$null; "
                f"[void][Management.Automation.Language.Parser]::ParseFile('{worker}',"
                "[ref]$null,[ref]$errors); "
                "if($errors.Count){$errors|ForEach-Object{Write-Error $_};exit 1}"
            )
            parsed = subprocess.run(
                [powershell, "-NoProfile", "-Command", command],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(parsed.returncode, 0, parsed.stderr)
            source = worker.read_text(encoding="utf-8")
            self.assertIn("[IO.FileShare]::Read", source)
            self.assertIn("$lockHandle.Dispose()", source)

    def test_worktree_guard_executes_and_detects_a_write(self) -> None:
        powershell = shutil.which("powershell")
        if not powershell:
            self.skipTest("Windows PowerShell is unavailable")
        guard_source = generated_powershell(
            label_block(self.install, "prepare_nvim_worktree_guard"),
            "NVIM_WORKTREE_PS",
        )
        with tempfile.TemporaryDirectory(prefix="cp_worktree_guard_") as temporary:
            base = Path(temporary)
            worktree = base / "repo"
            (worktree / ".git").mkdir(parents=True)
            (worktree / "nvim").mkdir()
            tracked = worktree / "nvim" / "lazy-lock.json"
            tracked.write_text('{"plugin":"v1"}\n', encoding="utf-8")
            (worktree / ".git" / "config").write_text("ignored\n", encoding="utf-8")
            guard = base / "guard.ps1"
            snapshot = base / "worktree.snapshot"
            guard.write_text(guard_source, encoding="utf-8")

            def invoke(mode: str) -> subprocess.CompletedProcess[str]:
                return subprocess.run(
                    [
                        powershell,
                        "-NoLogo",
                        "-NoProfile",
                        "-NonInteractive",
                        "-ExecutionPolicy",
                        "Bypass",
                        "-File",
                        str(guard),
                        "-Mode",
                        mode,
                        "-Root",
                        str(worktree),
                        "-Snapshot",
                        str(snapshot),
                    ],
                    text=True,
                    capture_output=True,
                    timeout=15,
                    check=False,
                )

            captured = invoke("capture")
            self.assertEqual(captured.returncode, 0, captured.stderr)
            unchanged = invoke("verify")
            self.assertEqual(unchanged.returncode, 0, unchanged.stderr)

            tracked.write_text('{"plugin":"v2"}\n', encoding="utf-8")
            changed = invoke("verify")
            self.assertNotEqual(changed.returncode, 0)
            self.assertIn(
                "The setup worktree changed during Neovim bootstrap",
                changed.stderr + changed.stdout,
            )


if __name__ == "__main__":
    unittest.main()
