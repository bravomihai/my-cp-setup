import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "scripts" / "install.bat"
UNINSTALLER = ROOT / "scripts" / "uninstall.bat"


def label_block(source: str, label: str) -> str:
    match = re.search(
        rf"(?ms)^:{re.escape(label)}\s*$\n(.*?)(?=^:[A-Za-z0-9_]+\s*$|\Z)",
        source,
    )
    if not match:
        raise AssertionError(f"missing batch label: {label}")
    return match.group(1)


class InstallerMsys2SilentContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = INSTALLER.read_text(encoding="utf-8")
        cls.ensure_msys2 = label_block(cls.source, "ensure_msys2")
        cls.uninstall_source = UNINSTALLER.read_text(encoding="utf-8")
        cls.uninstall_msys2 = label_block(cls.uninstall_source, "uninstall_msys2")

    def test_winget_and_qtifw_are_both_non_interactive(self) -> None:
        self.assertIn('set "WINGET_QUIET_ARGS=%WINGET_ARGS% --silent"', self.source)
        for switch in (
            "--accept-package-agreements",
            "--accept-source-agreements",
            "--disable-interactivity",
        ):
            self.assertIn(switch, self.source)

        expected = (
            'set "INSTALL_CMD=!WINGET! install --id MSYS2.MSYS2 '
            '%WINGET_QUIET_ARGS% --override "in --confirm-command '
            "--accept-messages --accept-licenses --root C:\\msys64 "
            'AllUsers=true""'
        )
        self.assertIn(expected, self.ensure_msys2)
        self.assertNotIn('--override "install ', self.ensure_msys2)

    def test_existing_spinner_and_post_install_validation_remain_in_order(self) -> None:
        required = (
            'set "INSTALL_CMD=',
            'call :run_install_spinner "MSYS2 via winget: MSYS2.MSYS2" "" '
            '"%VISIBLE_TEMP%\\cp_setup_winget.log" "INSTALLING" "INSTALLED" "1"',
            'call :capture_winget_install_result "MSYS2.MSYS2" "Winget.MSYS2"',
            "call :validate_msys2_tree",
            "call :find_msys2_shell quiet",
            'call :record_component_path "Winget.MSYS2" "!MSYS2_SHELL!"',
            'call :print_installed "MSYS2 via winget: MSYS2.MSYS2" "!MSYS2_SHELL!"',
        )
        positions = [self.ensure_msys2.index(fragment) for fragment in required]
        self.assertEqual(positions, sorted(positions))

    def test_native_uninstaller_is_headless_primary_with_winget_fallback(self) -> None:
        native = self.uninstall_msys2
        self.assertIn(
            'set "UNINSTALL_CMD="!MANAGED_MSYS2_UNINSTALLER!" pr --confirm-command"',
            native,
        )
        self.assertIn("call :validate_native_msys2_uninstaller", native)
        self.assertIn("goto uninstall_msys2_winget", native)
        self.assertLess(
            native.index("MANAGED_MSYS2_UNINSTALLER"),
            native.index("goto uninstall_msys2_winget"),
        )
        self.assertNotRegex(
            native, r"(?i)uninstall\.exe[^\r\n]*(?:--show|gui|interactive)"
        )

        spinner = label_block(self.uninstall_source, "run_command_spinner")
        self.assertIn("-WindowStyle Hidden", spinner)
        fallback = label_block(self.uninstall_source, "uninstall_winget_now")
        for switch in ("--disable-interactivity", "--silent", "--exact"):
            self.assertIn(switch, fallback)

    def test_native_uninstall_artifact_snapshot_brackets_the_headless_run(self) -> None:
        native = self.uninstall_msys2
        before = native.index('call :capture_native_msys2_artifacts "before"')
        command = native.index("pr --confirm-command")
        spinner = native.index('call :run_command_spinner "MSYS2"')
        after = native.index('call :capture_native_msys2_artifacts "after"')
        self.assertLess(before, command)
        self.assertLess(command, spinner)
        self.assertLess(spinner, after)
        self.assertIn("NATIVE_ARTIFACT_EXIT", native)
        self.assertIn("native_msys2_uninstall_failed", native)


if __name__ == "__main__":
    unittest.main()
