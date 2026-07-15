import re
import subprocess
import unittest
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BATCH_SCRIPTS = (
    ROOT / "scripts" / "install.bat",
    ROOT / "scripts" / "uninstall.bat",
)
LABEL = re.compile(r"^:([A-Za-z0-9_]+)\s*$")
REFERENCE = re.compile(r"\b(?:call\s+:|goto\s+:?)([A-Za-z0-9_]+)\b", re.IGNORECASE)
BLOCK_MARKER = re.compile(r"(__CP_[A-Z0-9_]+)_(BEGIN|END)__")


class BatchStructureTests(unittest.TestCase):
    def test_batch_files_have_release_safe_physical_format(self) -> None:
        for path in BATCH_SCRIPTS:
            with self.subTest(script=path.name):
                data = path.read_bytes()
                self.assertFalse(
                    data.startswith(b"\xef\xbb\xbf"), f"BOM in {path.name}"
                )
                remainder = data.replace(b"\r\n", b"")
                self.assertEqual(remainder.count(b"\n"), 0, f"bare LF in {path.name}")
                self.assertEqual(remainder.count(b"\r"), 0, f"bare CR in {path.name}")
                longest = max((len(line) for line in data.split(b"\r\n")), default=0)
                self.assertLess(longest, 8191, f"CMD line limit risk in {path.name}")

    def test_no_unbounded_or_interactive_child_waits_remain(self) -> None:
        for path in BATCH_SCRIPTS:
            with self.subTest(script=path.name):
                text = path.read_text(encoding="utf-8")
                self.assertNotRegex(text, r"(?im)^\s*pause(?:\s|$)")
                self.assertNotIn("ReadKey", text)
                self.assertNotRegex(text, r"(?i)\.WaitForExit\(\s*\)")
                self.assertNotRegex(text, r"(?i)Receive-Job\s+-Wait\b")
                self.assertNotIn("Get-CimInstance", text)

    def test_ansi_is_initialized_before_early_failures(self) -> None:
        for path in BATCH_SCRIPTS:
            with self.subTest(script=path.name):
                text = path.read_text(encoding="utf-8")
                parse = text.index("\n:parse_args\n")
                call = (
                    text.index("call :enable_console_ansi")
                    if path.name == "install.bat"
                    else text.index("call :enable_ansi")
                )
                self.assertLess(call, parse)

    def test_direct_invalid_cli_returns_failure_with_formatted_status(self) -> None:
        for path in BATCH_SCRIPTS:
            with self.subTest(script=path.name):
                result = subprocess.run(
                    ["cmd.exe", "/d", "/c", str(path), "--cp-contract-invalid"],
                    cwd=ROOT,
                    capture_output=True,
                    text=True,
                    timeout=30,
                    check=False,
                )
                output = result.stdout + result.stderr
                self.assertEqual(1, result.returncode, output)
                self.assertIn("FAILED", output)
                self.assertNotIn("[[31m", output)

    def test_labels_are_unique_and_all_literal_references_resolve(self) -> None:
        for path in BATCH_SCRIPTS:
            with self.subTest(script=path.name):
                lines = path.read_text(encoding="utf-8").splitlines()
                labels = [
                    match.group(1).lower()
                    for line in lines
                    if (match := LABEL.fullmatch(line))
                ]
                duplicates = sorted(
                    name for name, count in Counter(labels).items() if count != 1
                )
                self.assertEqual(duplicates, [], f"duplicate labels in {path.name}")

                known = set(labels)
                unresolved: list[tuple[int, str]] = []
                for number, line in enumerate(lines, 1):
                    if line.startswith("::"):
                        continue
                    for match in REFERENCE.finditer(line):
                        target = match.group(1).lower()
                        if target != "eof" and target not in known:
                            unresolved.append((number, target))
                self.assertEqual(
                    unresolved,
                    [],
                    f"unresolved literal call/goto targets in {path.name}",
                )

    def test_every_embedded_block_reference_has_one_well_formed_pair(self) -> None:
        for path in BATCH_SCRIPTS:
            with self.subTest(script=path.name):
                lines = path.read_text(encoding="utf-8").splitlines()
                referenced = {
                    match.group(1)
                    for line in lines
                    for match in BLOCK_MARKER.finditer(line)
                }
                self.assertTrue(referenced, f"no embedded blocks found in {path.name}")
                for name in sorted(referenced):
                    begin = f"::{name}_BEGIN__"
                    end = f"::{name}_END__"
                    self.assertEqual(
                        lines.count(begin), 1, f"invalid begin marker for {name}"
                    )
                    self.assertEqual(
                        lines.count(end), 1, f"invalid end marker for {name}"
                    )
                    first = lines.index(begin)
                    last = lines.index(end)
                    self.assertLess(first, last, f"reversed markers for {name}")
                    malformed = [
                        (number, line)
                        for number, line in enumerate(
                            lines[first + 1 : last], first + 2
                        )
                        if not line.startswith("::")
                    ]
                    self.assertEqual(
                        malformed, [], f"non-comment payload lines in block {name}"
                    )


if __name__ == "__main__":
    unittest.main()
