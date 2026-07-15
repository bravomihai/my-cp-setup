import contextlib
import importlib.util
import io
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_SCRIPT = ROOT / "scripts" / "run.py"
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def load_run_module():
    spec = importlib.util.spec_from_file_location("cp_run_contract", RUN_SCRIPT)
    if spec is None or spec.loader is None:
        raise AssertionError("could not load scripts/run.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def plain(value: str) -> str:
    return ANSI.sub("", value)


class RunOutputContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.run_module = load_run_module()

    def verify(
        self, result: subprocess.CompletedProcess[bytes], expected: bytes
    ) -> tuple[int, str, str]:
        with tempfile.TemporaryDirectory(prefix="cp_run_contract_") as temporary:
            expected_path = Path(temporary) / "expected.txt"
            expected_path.write_bytes(expected)
            stdout = io.StringIO()
            stderr = io.StringIO()
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                code = self.run_module.verify_result(result, expected_path)
        return code, plain(stdout.getvalue()), plain(stderr.getvalue())

    def test_pass_precedes_stderr_then_two_blank_lines_and_done_timer(self) -> None:
        result = subprocess.CompletedProcess(
            args=["solve"], returncode=0, stdout=b"hello\n", stderr=b"note\n0.25 s\n"
        )
        code, stdout, stderr = self.verify(result, b"hello\n")

        self.assertEqual(code, 0)
        self.assertEqual(stderr, "")
        self.assertEqual(
            stdout,
            "[PASS]\n[STDERR]\nnote\n\n\n[DONE] 0.250000s\n",
        )

    def test_timer_only_stderr_is_reported_empty(self) -> None:
        result = subprocess.CompletedProcess(
            args=["solve"], returncode=0, stdout=b"ok\n", stderr=b"0.001 s\n"
        )
        code, stdout, _ = self.verify(result, b"ok\n")

        self.assertEqual(code, 0)
        self.assertEqual(
            stdout,
            "[PASS]\n[STDERR EMPTY]\n\n\n[DONE] 0.001000s\n",
        )

    def test_fail_reports_precise_line_column_before_stderr_and_done(self) -> None:
        result = subprocess.CompletedProcess(
            args=["solve"],
            returncode=0,
            stdout=b"Hello, World!\n",
            stderr=b"0.5 s\n",
        )
        code, stdout, _ = self.verify(result, b"Hello, Worl!\n")

        self.assertEqual(code, 1)
        self.assertIn("[FAIL] first difference at line 1, column 12", stdout)
        self.assertIn("--- expected.txt", stdout)
        self.assertIn("+++ program output", stdout)
        self.assertIn("-Hello, Worl!", stdout)
        self.assertIn("+Hello, World!", stdout)
        self.assertLess(stdout.index("[FAIL]"), stdout.index("[STDERR EMPTY]"))
        self.assertLess(stdout.index("[STDERR EMPTY]"), stdout.index("[DONE]"))
        self.assertTrue(stdout.endswith("[STDERR EMPTY]\n\n\n[DONE] 0.500000s\n"))

    def test_runtime_error_never_prints_done(self) -> None:
        result = subprocess.CompletedProcess(
            args=["solve"], returncode=7, stdout=b"partial\n", stderr=b"boom\n0.2 s\n"
        )
        code, stdout, stderr = self.verify(result, b"partial\n")

        self.assertEqual(code, 7)
        self.assertEqual(stderr, "")
        self.assertEqual(stdout, "[RUNTIME ERROR: exit code 7]\n[STDERR]\nboom\n")
        self.assertNotIn("DONE", stdout)

    def test_normal_run_keeps_done_and_timer_on_one_line(self) -> None:
        result = subprocess.CompletedProcess(
            args=["solve"], returncode=0, stdout=None, stderr=b"0.125 s\n"
        )
        stdout = io.StringIO()
        stderr = io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            code = self.run_module.finish_run(result)

        lines = [line for line in plain(stdout.getvalue()).splitlines() if line]
        self.assertEqual(code, 0)
        self.assertEqual(stderr.getvalue(), "")
        self.assertEqual(lines, ["[DONE] 0.125000s"])


if __name__ == "__main__":
    unittest.main()
