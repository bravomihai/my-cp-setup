import argparse
import ast
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path


RED = "\033[31m"
RESET = "\033[0m"


def done(message: str) -> None:
    print(message)


def failed(message: str) -> None:
    print(f"[{RED}EXPAND FAILED{RESET}] {message}", file=sys.stderr)


def atomic_write_text(path: Path, text: str) -> None:
    fd, tmp_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    tmp = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as output:
            fd = -1
            output.write(text)
            output.flush()
            os.fsync(output.fileno())
        for attempt in range(6):
            try:
                os.replace(tmp, path)
                break
            except PermissionError:
                if attempt == 5:
                    raise
                time.sleep(0.01 * (attempt + 1))
    except Exception:
        if fd != -1:
            os.close(fd)
        tmp.unlink(missing_ok=True)
        raise


def copy_to_clipboard(path: Path) -> None:
    clip = shutil.which("clip")
    if clip is None:
        print(
            "[WARN] clip.exe not found; submit file was not copied to clipboard.",
            file=sys.stderr,
        )
        return

    try:
        subprocess.run(
            [clip],
            input=b"\xff\xfe" + path.read_text(encoding="utf-8").encode("utf-16le"),
            check=True,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError:
        print(
            "[WARN] Clipboard copy failed; submit file was generated.", file=sys.stderr
        )


def expand_cpp(source: Path, root: Path) -> Path:
    cp_lib = root / "libraries" / "cpp" / "my_libraries" / "cp.hpp"
    acl = root / "libraries" / "ac-library"
    expander = acl / "expander.py"

    for path in (cp_lib, expander):
        if not path.exists():
            raise RuntimeError(f"missing required file: {path}")

    text = "\n\n".join(
        [
            "#define DISABLE_DEBUG",
            cp_lib.read_text(encoding="utf-8"),
            source.read_text(encoding="utf-8-sig"),
        ]
    )
    text = re.sub(
        r"(?m)^\s*#\s*include\s+[<\"]my_libraries/cp\.hpp[>\"]\s*\n?", "", text
    )
    text = re.sub(r"(?m)^\s*#\s*include\s+[<\"]debug\.cpp[>\"]\s*\n?", "", text)
    text = re.sub(r"(?m)^\s*#\s*pragma\s+once\s*\n?", "", text)

    fd, tmp_name = tempfile.mkstemp(
        prefix=".cp_expand_", suffix=".cpp", dir=source.parent
    )
    os.close(fd)
    tmp = Path(tmp_name)
    out = source.parent / "submit.cpp"

    try:
        tmp.write_text(text, encoding="utf-8")
        result = subprocess.run(
            [sys.executable, str(expander), "-c", str(tmp)],
            cwd=acl,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            check=True,
        )
        atomic_write_text(out, result.stdout)
    except subprocess.CalledProcessError as exc:
        if exc.stderr:
            print(exc.stderr, file=sys.stderr, end="")
        raise RuntimeError("AtCoder expander failed") from exc
    finally:
        tmp.unlink(missing_ok=True)

    return out


JAVA_IMPORT_RE = re.compile(
    r"(?m)^[ \t]*(import[ \t]+(?:static[ \t]+)?[^;\r\n]+;)[ \t]*(?://[^\r\n]*)?(?:\r?\n|$)"
)
JAVA_PACKAGE_RE = re.compile(
    r"(?m)^[ \t]*package[ \t]+[^;\r\n]+;[ \t]*(?://[^\r\n]*)?(?:\r?\n|$)"
)
JAVA_PUBLIC_CLASS_RE = re.compile(
    r"\bpublic\s+(?:(?:abstract|final|sealed|non-sealed|strictfp)\s+|"
    r"@[A-Za-z_$][A-Za-z0-9_$.]*(?:\s*\([^{};]*\))?\s+)*"
    r"class\s+([A-Za-z_$][A-Za-z0-9_$]*)\b"
)


def extract_java_imports(text: str) -> tuple[str, list[str]]:
    imports = []
    masked = mask_java_non_code(text)
    matches = list(JAVA_IMPORT_RE.finditer(masked))

    for match in matches:
        statement = re.sub(r"[ \t]+", " ", text[match.start(1) : match.end(1)].strip())
        is_static = statement.startswith("import static ")
        target = re.sub(r"^import\s+(?:static\s+)?", "", statement).rstrip(";").strip()
        if target == "my_libraries.Cp" or target.startswith("my_libraries.Cp."):
            if is_static:
                raise RuntimeError(
                    "static imports from my_libraries.Cp are not supported; "
                    "use import my_libraries.Cp and Cp.member(...)"
                )
        else:
            imports.append(statement)

    for match in reversed(matches):
        text = text[: match.start()] + text[match.end() :]
    return text, imports


def mask_java_non_code(text: str) -> str:
    masked = list(text)
    i = 0
    while i < len(text):
        end = i
        if text.startswith("//", i):
            end = text.find("\n", i + 2)
            if end == -1:
                end = len(text)
        elif text.startswith("/*", i):
            close = text.find("*/", i + 2)
            end = len(text) if close == -1 else close + 2
        elif text.startswith('"""', i):
            close = text.find('"""', i + 3)
            end = len(text) if close == -1 else close + 3
        elif text[i] in {'"', "'"}:
            quote = text[i]
            end = i + 1
            while end < len(text):
                if text[end] == "\\":
                    end += 2
                    continue
                end += 1
                if text[end - 1] == quote:
                    break

        if end > i:
            for j in range(i, min(end, len(text))):
                if masked[j] not in "\r\n":
                    masked[j] = " "
            i = end
        else:
            i += 1
    return "".join(masked)


def remove_java_packages(text: str) -> str:
    masked = mask_java_non_code(text)
    for match in reversed(list(JAVA_PACKAGE_RE.finditer(masked))):
        text = text[: match.start()] + text[match.end() :]
    return text


def rename_java_main_class(text: str) -> str:
    masked = mask_java_non_code(text)
    depth = 0
    position = 0
    selected = None

    for match in JAVA_PUBLIC_CLASS_RE.finditer(masked):
        for char in masked[position : match.start()]:
            if char == "{":
                depth += 1
            elif char == "}":
                depth = max(0, depth - 1)
        position = match.start()
        if depth == 0:
            selected = match
            break

    if selected is None:
        raise RuntimeError("no top-level public Java class found")

    old_name = selected.group(1)
    if old_name == "Main":
        return text

    identifier = re.compile(
        rf"(?<![A-Za-z0-9_$]){re.escape(old_name)}(?![A-Za-z0-9_$])"
    )
    matches = list(identifier.finditer(masked))
    for match in reversed(matches):
        text = text[: match.start()] + "Main" + text[match.end() :]
    return text


def expand_java(source: Path, root: Path) -> Path:
    lib = root / "libraries" / "java" / "my_libraries" / "Cp.java"
    if not lib.exists():
        raise RuntimeError(f"missing Java library: {lib}")

    lib_text = lib.read_text(encoding="utf-8")
    src_text = source.read_text(encoding="utf-8-sig")

    lib_text = remove_java_packages(lib_text)
    src_text = remove_java_packages(src_text)
    lib_text, lib_imports = extract_java_imports(lib_text)
    src_text, src_imports = extract_java_imports(src_text)

    imports = []
    seen_imports = set()
    for statement in lib_imports + src_imports:
        key = re.sub(r"\s+", "", statement)
        if key not in seen_imports:
            seen_imports.add(key)
            imports.append(statement)

    lib_text = re.sub(r"\bpublic\s+final\s+class\s+Cp\b", "final class Cp", lib_text)
    lib_text = re.sub(
        r"\bpublic\s+static\s+final\s+boolean\s+DEBUG\s*=\s*true\s*;",
        "public static final boolean DEBUG = false;",
        lib_text,
    )
    src_text = rename_java_main_class(src_text)

    out = source.parent / "submit.java"
    parts = []
    if imports:
        parts.append("\n".join(imports))
    parts.extend([lib_text.strip(), src_text.strip()])
    atomic_write_text(out, "\n\n".join(parts) + "\n")
    return out


PYTHON_CODING_RE = re.compile(r"^[ \t\f]*#.*?coding[:=][ \t]*[-_.a-zA-Z0-9]+")


def remove_python_helper_imports(text: str) -> str:
    tree = ast.parse(text)
    qualified_imports = [
        node
        for node in ast.walk(tree)
        if (
            isinstance(node, ast.Import)
            and any(name.name == "my_libraries.cp" for name in node.names)
        )
        or (
            isinstance(node, ast.ImportFrom)
            and node.module == "my_libraries"
            and any(name.name == "cp" for name in node.names)
        )
    ]
    if qualified_imports:
        raise RuntimeError(
            "qualified imports of my_libraries.cp are not supported; "
            "use from my_libraries.cp import ..."
        )

    helper_imports = [
        node
        for node in ast.walk(tree)
        if isinstance(node, ast.ImportFrom) and node.module == "my_libraries.cp"
    ]
    top_level_ids = {id(node) for node in tree.body}
    lines = text.splitlines(keepends=True)

    for node in helper_imports:
        if id(node) not in top_level_ids:
            raise RuntimeError("imports from my_libraries.cp must be at module level")
        if any(name.asname for name in node.names):
            raise RuntimeError(
                "aliased imports from my_libraries.cp are not supported in submissions"
            )

    for node in sorted(helper_imports, key=lambda item: item.lineno, reverse=True):
        start = node.lineno - 1
        end = (node.end_lineno or node.lineno) - 1
        prefix = lines[start][: node.col_offset]
        suffix = lines[end][node.end_col_offset or 0 :]
        if prefix.strip() or (suffix.strip() and not suffix.lstrip().startswith("#")):
            raise RuntimeError(
                "imports from my_libraries.cp must use their own statement"
            )
        for index in range(start, end + 1):
            ending = (
                "\r\n"
                if lines[index].endswith("\r\n")
                else "\n"
                if lines[index].endswith("\n")
                else ""
            )
            lines[index] = ending

    return "".join(lines)


def split_python_preamble(text: str) -> tuple[str, str]:
    tree = ast.parse(text)
    lines = text.splitlines(keepends=True)
    preamble_end = 0

    if lines and lines[0].startswith("#!"):
        preamble_end = 1
    for index in range(min(2, len(lines))):
        if PYTHON_CODING_RE.match(lines[index]):
            preamble_end = max(preamble_end, index + 1)

    body_index = 0
    if tree.body:
        first = tree.body[0]
        if (
            isinstance(first, ast.Expr)
            and isinstance(first.value, ast.Constant)
            and isinstance(first.value.value, str)
        ):
            preamble_end = max(preamble_end, first.end_lineno or first.lineno)
            body_index = 1

    while body_index < len(tree.body):
        node = tree.body[body_index]
        if not isinstance(node, ast.ImportFrom) or node.module != "__future__":
            break
        preamble_end = max(preamble_end, node.end_lineno or node.lineno)
        body_index += 1

    preamble = "".join(lines[:preamble_end]).rstrip()
    body = "".join(lines[preamble_end:]).lstrip("\r\n")
    return preamble, body


def expand_python(source: Path, root: Path) -> Path:
    lib = root / "libraries" / "python" / "my_libraries" / "cp.py"
    if not lib.exists():
        raise RuntimeError(f"missing Python library: {lib}")

    lib_text = lib.read_text(encoding="utf-8")
    src_text = source.read_text(encoding="utf-8-sig")
    lib_text = re.sub(r"(?m)^DEBUG\s*=\s*True\s*$", "DEBUG = False", lib_text)
    src_text = remove_python_helper_imports(src_text)
    preamble, src_text = split_python_preamble(src_text)

    out = source.parent / "submit.py"
    parts = []
    if preamble:
        parts.append(preamble)
    parts.extend([lib_text.strip(), src_text.strip()])
    atomic_write_text(out, "\n\n".join(part for part in parts if part) + "\n")
    return out


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Expand CP source files for submission."
    )
    parser.add_argument(
        "--no-clipboard",
        action="store_true",
        help="Generate the submit file without copying it to the clipboard.",
    )
    parser.add_argument("source", help="Path to a .cpp, .java, or .py file")
    args = parser.parse_args()

    source = Path(args.source).resolve()
    root = Path(__file__).resolve().parents[1]

    if not source.is_file():
        failed(f"Source is not a file: {source}")
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

    if not args.no_clipboard:
        copy_to_clipboard(out)
    done(f"{out.name} generated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
