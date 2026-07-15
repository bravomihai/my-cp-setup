import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXPAND = ROOT / "scripts" / "expand.py"
PYTHON_LIBRARY = ROOT / "libraries" / "python"

COLLISION_SOURCE = """\
from my_libraries.cp import *

helper_print = print_
helper_flush = flush
helper_out = out
helper_timer_out = timer_out
helper_timer = Timer
helper_token = token
helper_ni = ni

DEBUG = True
sys = time = _tokens = _out = _builtins = _get_tokens = None
eprint = out = print_ = print_iter = flush = Timer = None
range = int = float = next = iter = map = str = min = max = print = None


def main():
    timer = helper_timer()
    helper_out("local diagnostic")
    helper_timer_out(timer.elapsed())
    helper_print(helper_token(), helper_ni())
    helper_flush()


if __name__ == "__main__":
    main()
"""


class PythonExpansionIsolationTest(unittest.TestCase):
    def run_source(
        self, source: Path, *, local: bool
    ) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        if local:
            current = env.get("PYTHONPATH")
            env["PYTHONPATH"] = str(PYTHON_LIBRARY) + (
                os.pathsep + current if current else ""
            )

        return subprocess.run(
            [sys.executable, str(source)],
            cwd=source.parent,
            env=env,
            input="word 7\n",
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )

    def test_solution_globals_cannot_change_inlined_helper_state(self):
        with tempfile.TemporaryDirectory(prefix="cp_python_expand_") as temp:
            source = Path(temp) / "solve.py"
            source.write_text(COLLISION_SOURCE, encoding="utf-8")

            local = self.run_source(source, local=True)
            self.assertEqual(local.returncode, 0, local.stderr)
            self.assertEqual(local.stdout, "word 7\n")
            self.assertIn("local diagnostic", local.stderr)

            expanded = subprocess.run(
                [sys.executable, str(EXPAND), "--no-clipboard", str(source)],
                cwd=ROOT,
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )
            self.assertEqual(expanded.returncode, 0, expanded.stderr or expanded.stdout)

            submission = source.with_name("submit.py")
            judge = self.run_source(submission, local=False)
            self.assertEqual(judge.returncode, 0, judge.stderr)
            self.assertEqual(judge.stdout, "word 7\n")
            self.assertEqual(judge.stderr, "")


if __name__ == "__main__":
    unittest.main()
