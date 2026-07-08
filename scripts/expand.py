import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path


GREEN = "\033[32m"
RED = "\033[31m"
RESET = "\033[0m"


def done(message: str) -> None:
    print(f"[{GREEN}DONE{RESET}] {message}")


def failed(message: str) -> None:
    print(f"[{RED}EXPAND FAILED{RESET}] {message}", file=sys.stderr)


def copy_to_clipboard(path: Path) -> None:
    clip = shutil.which("clip")
    if clip is None:
        print("[WARN] clip.exe not found; submit file was not copied to clipboard.", file=sys.stderr)
        return

    try:
        subprocess.run(
            [clip],
            input=b"\xff\xfe" + path.read_text(encoding="utf-8").encode("utf-16le"),
            check=True,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError:
        print("[WARN] Clipboard copy failed; submit file was generated.", file=sys.stderr)


def expand_cpp(source: Path, root: Path) -> Path:
    debug_lib = root / "libraries" / "cpp" / "my_libraries" / "debug.cpp"
    cp_lib = root / "libraries" / "cpp" / "my_libraries" / "cp.hpp"
    acl = root / "libraries" / "ac-library"
    expander = acl / "expander.py"

    for path in (debug_lib, cp_lib, expander):
        if not path.exists():
            raise RuntimeError(f"missing required file: {path}")

    tmp = source.parent / "solve_expand.cpp"
    out = source.parent / "submit.cpp"

    text = "\n\n".join(
        [
            debug_lib.read_text(encoding="utf-8"),
            cp_lib.read_text(encoding="utf-8"),
            source.read_text(encoding="utf-8"),
        ]
    )
    text = re.sub(r"(?m)^\s*#\s*include\s+[<\"]my_libraries/cp\.hpp[>\"]\s*\n?", "", text)
    text = re.sub(r"(?m)^\s*#\s*include\s+[<\"]debug\.cpp[>\"]\s*\n?", "", text)
    text = re.sub(r"(?m)^\s*#\s*pragma\s+once\s*\n?", "", text)

    try:
        tmp.write_text(text, encoding="utf-8")
        with out.open("w", encoding="utf-8", newline="") as output:
            subprocess.run(
                [sys.executable, str(expander), "-c", str(tmp)],
                cwd=acl,
                stdout=output,
                stderr=subprocess.PIPE,
                text=True,
                check=True,
            )
    except subprocess.CalledProcessError as exc:
        if exc.stderr:
            print(exc.stderr, file=sys.stderr, end="")
        raise RuntimeError("AtCoder expander failed") from exc
    finally:
        tmp.unlink(missing_ok=True)

    copy_to_clipboard(out)
    return out


def expand_java(source: Path, root: Path) -> Path:
    lib = root / "libraries" / "java" / "my_libraries" / "Cp.java"
    if not lib.exists():
        raise RuntimeError(f"missing Java library: {lib}")

    lib_text = lib.read_text(encoding="utf-8")
    src_text = source.read_text(encoding="utf-8")

    lib_text = re.sub(r"(?m)^package\s+my_libraries;\s*\n?", "", lib_text)
    lib_text = re.sub(r"\bpublic\s+final\s+class\s+Cp\b", "final class Cp", lib_text)
    lib_text = re.sub(r"\bpublic\s+static\s+final\s+boolean\s+DEBUG\s*=\s*true\s*;", "public static final boolean DEBUG = false;", lib_text)
    src_text = re.sub(r"(?m)^import\s+my_libraries\.Cp;\s*\n?", "", src_text)
    src_text = re.sub(r"(?m)^import\s+static\s+my_libraries\.Cp\.\*;\s*\n?", "", src_text)
    src_text = re.sub(r"\bpublic\s+class\s+solve\b", "class solve", src_text)

    out = source.parent / "submit.java"
    out.write_text(lib_text.rstrip() + "\n\n" + src_text.lstrip(), encoding="utf-8")
    copy_to_clipboard(out)
    return out


def expand_python(source: Path, root: Path) -> Path:
    lib = root / "libraries" / "python" / "my_libraries" / "cp.py"
    if not lib.exists():
        raise RuntimeError(f"missing Python library: {lib}")

    lib_text = lib.read_text(encoding="utf-8")
    src_text = source.read_text(encoding="utf-8")
    lib_text = re.sub(r"(?m)^DEBUG\s*=\s*True\s*$", "DEBUG = False", lib_text)
    src_text = re.sub(r"(?m)^from\s+my_libraries\.cp\s+import\s+\*\s*\n?", "", src_text)

    out = source.parent / "submit.py"
    out.write_text(lib_text.rstrip() + "\n\n" + src_text.lstrip(), encoding="utf-8")
    copy_to_clipboard(out)
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description="Expand CP source files for submission.")
    parser.add_argument("source", help="Path to a .cpp, .java, or .py file")
    args = parser.parse_args()

    source = Path(args.source).resolve()
    root = Path(__file__).resolve().parents[1]

    if not source.exists():
        failed(f"File not found: {source}")
        return 1

    try:
        if source.suffix.lower() == ".cpp":
            out = expand_cpp(source, root)
        elif source.suffix.lower() == ".java":
            out = expand_java(source, root)
        elif source.suffix.lower() == ".py":
            out = expand_python(source, root)
        else:
            failed(f"Unsupported file type: {source.suffix}")
            return 1
    except Exception as exc:
        failed(str(exc))
        return 1

    done(f"{out.name} generated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
