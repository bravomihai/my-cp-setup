import argparse
import difflib
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from subprocess import list2cmdline


GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"
VERIFY_TIMEOUT_SECONDS = 5
TIMER_LINE = re.compile(r"([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\s*s")


for stream in (sys.stdout, sys.stderr):
    if hasattr(stream, "reconfigure"):
        stream.reconfigure(errors="backslashreplace")


def done(timer: str | None = None) -> None:
    suffix = f" {timer}" if timer is not None else ""
    print(f"[{GREEN}DONE{RESET}]{suffix}")


def failed(label: str) -> None:
    print(f"[{RED}{label}{RESET}]", file=sys.stderr)


def open_new_cmd(source: Path, verify: bool = False) -> int:
    if os.name != "nt":
        print("--new-cmd is only supported on Windows.", file=sys.stderr)
        return 1

    arguments = [sys.executable, str(Path(__file__).resolve())]
    if verify:
        arguments.append("--verify")
    arguments.append(str(source))
    run_command_line = list2cmdline(arguments)
    run_command_line = f"{run_command_line} & echo. & pause"
    subprocess.Popen(
        [
            "cmd",
            "/c",
            "start",
            "",
            "/D",
            str(source.parent),
            "cmd",
            "/c",
            run_command_line,
        ]
    )
    return 0


def selected_input(source: Path) -> Path | None:
    debug_input = source.parent / "debug" / "input.txt"
    local_input = source.parent / "input.txt"
    for path in (local_input, debug_input):
        if path.is_file():
            return path
        if path.exists():
            raise IsADirectoryError(f"Input path is not a file: {path}")
    return None


def normalized_lines(data: bytes) -> list[str]:
    text = (
        data.decode("utf-8", errors="surrogateescape")
        .replace("\r\n", "\n")
        .replace("\r", "\n")
    )
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    return [line.rstrip() for line in lines]


def safe_display(text: str) -> str:
    return text.encode("utf-8", errors="surrogateescape").decode(
        "utf-8", errors="backslashreplace"
    )


def first_difference(expected: list[str], actual: list[str]) -> tuple[int, int]:
    for line_index in range(max(len(expected), len(actual))):
        expected_line = expected[line_index] if line_index < len(expected) else ""
        actual_line = actual[line_index] if line_index < len(actual) else ""
        if (
            expected_line != actual_line
            or line_index >= len(expected)
            or line_index >= len(actual)
        ):
            for column_index in range(max(len(expected_line), len(actual_line))):
                expected_char = (
                    expected_line[column_index]
                    if column_index < len(expected_line)
                    else None
                )
                actual_char = (
                    actual_line[column_index]
                    if column_index < len(actual_line)
                    else None
                )
                if expected_char != actual_char:
                    return line_index + 1, column_index + 1
            return line_index + 1, min(len(expected_line), len(actual_line)) + 1
    return 1, 1


def parsed_stderr(data: bytes) -> tuple[list[str], str | None]:
    stderr_text = (
        data.decode("utf-8", errors="replace").replace("\r\n", "\n").replace("\r", "\n")
    )
    stderr_lines = [line for line in stderr_text.split("\n") if line.strip()]
    timer = None
    timer_match = (
        TIMER_LINE.fullmatch(stderr_lines[-1].strip()) if stderr_lines else None
    )
    if timer_match:
        timer = f"{float(timer_match.group(1)):.6f}s"
        stderr_lines.pop()
    return stderr_lines, timer


def verify_result(
    result: subprocess.CompletedProcess[bytes], expected_path: Path
) -> int:
    def show_stderr() -> str | None:
        stderr_lines, timer = parsed_stderr(result.stderr)

        if not stderr_lines:
            print(f"[{YELLOW}STDERR EMPTY{RESET}]")
        else:
            print(f"[{YELLOW}STDERR{RESET}]")
            print("\n".join(stderr_lines))
        return timer

    if result.returncode != 0:
        print(f"[{RED}RUNTIME ERROR: exit code {result.returncode}{RESET}]")
        show_stderr()
        return result.returncode or 1

    expected = normalized_lines(expected_path.read_bytes())
    actual = normalized_lines(result.stdout)
    if expected == actual:
        print(f"[{GREEN}PASS{RESET}]")
        timer = show_stderr()
        print("\n")
        done(timer)
        return 0

    line, column = first_difference(expected, actual)
    print(f"[{RED}FAIL{RESET}] first difference at line {line}, column {column}")
    diff = difflib.unified_diff(
        expected, actual, fromfile="expected.txt", tofile="program output", lineterm=""
    )
    for index, diff_line in enumerate(diff):
        if index >= 40:
            print("... diff truncated ...")
            break
        print(safe_display(diff_line))
    timer = show_stderr()
    print("\n")
    done(timer)
    return 1


def capture_command(
    command: list[str],
    cwd: Path,
    input_path: Path | None,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[bytes] | None:
    try:
        if input_path is None:
            return subprocess.run(
                command,
                cwd=cwd,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
        with input_path.open("rb") as stdin:
            return subprocess.run(
                command,
                cwd=cwd,
                stdin=stdin,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=VERIFY_TIMEOUT_SECONDS,
            )
    except subprocess.TimeoutExpired as error:
        if error.stderr:
            sys.stderr.buffer.write(error.stderr)
        failed(f"TIMEOUT: exceeded {VERIFY_TIMEOUT_SECONDS}s")
        return None


def run_command(
    command: list[str],
    cwd: Path,
    input_path: Path | None = None,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[bytes]:
    if input_path is None:
        return subprocess.run(command, cwd=cwd, env=env, stderr=subprocess.PIPE)

    with input_path.open("rb") as stdin:
        return subprocess.run(
            command, cwd=cwd, stdin=stdin, env=env, stderr=subprocess.PIPE
        )


def finish_run(result: subprocess.CompletedProcess[bytes]) -> int:
    stderr_lines, timer = parsed_stderr(result.stderr)
    print("\n")
    if stderr_lines:
        print("\n".join(stderr_lines))
    if result.returncode != 0:
        failed("FAILED")
        return result.returncode
    done(timer)
    return 0


def run_cpp(
    source: Path, root: Path, input_path: Path | None, expected_path: Path | None = None
) -> int:
    with tempfile.TemporaryDirectory(prefix="cp_cpp_") as build_dir:
        exe = Path(build_dir) / "solve.exe"
        compiler = os.environ.get("CP_GPP") or "g++"
        compile_cmd = [
            compiler,
            "-std=c++20",
            "-O2",
            f"-I{root / 'libraries' / 'cpp'}",
            f"-I{root / 'libraries' / 'ac-library'}",
            str(source),
            "-o",
            str(exe),
        ]
        if subprocess.run(compile_cmd, cwd=source.parent).returncode != 0:
            failed("COMPILE FAILED")
            return 1

        if expected_path is not None:
            result = capture_command([str(exe)], source.parent, input_path)
            return verify_result(result, expected_path) if result is not None else 1

        return finish_run(run_command([str(exe)], source.parent, input_path))


def run_java(
    source: Path, root: Path, input_path: Path | None, expected_path: Path | None = None
) -> int:
    with tempfile.TemporaryDirectory(prefix="cp_java_") as build_dir_name:
        build_dir = Path(build_dir_name)
        compiler = os.environ.get("CP_JAVAC") or "javac"
        runtime = os.environ.get("CP_JAVA") or "java"
        classpath = f"{root / 'libraries' / 'java'};{source.parent}"

        def quoted_path(value: str | Path) -> str:
            return f'"{str(value).replace(chr(92), "/")}"'

        javac_args = [
            "-encoding",
            "UTF-8",
            "-cp",
            quoted_path(classpath),
            "-sourcepath",
            quoted_path(classpath),
            "-d",
            quoted_path(build_dir),
            quoted_path(source),
        ]
        argfile = build_dir / "javac.args"
        argfile.write_text("\n".join(javac_args) + "\n", encoding="utf-8", newline="\n")
        compile_cmd = [compiler, "@" + str(argfile).replace("\\", "/")]
        if subprocess.run(compile_cmd, cwd=source.parent).returncode != 0:
            failed("COMPILE FAILED")
            return 1

        command = [
            runtime,
            "-Dstdout.encoding=UTF-8",
            "-Dstderr.encoding=UTF-8",
            "-cp",
            f"{build_dir};{root / 'libraries' / 'java'}",
            source.stem,
        ]
        if expected_path is not None:
            result = capture_command(command, source.parent, input_path)
            return verify_result(result, expected_path) if result is not None else 1

        return finish_run(run_command(command, source.parent, input_path))


def run_python(
    source: Path, root: Path, input_path: Path | None, expected_path: Path | None = None
) -> int:
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    env["PYTHONIOENCODING"] = "utf-8"
    python_path = str(root / "libraries" / "python")
    env["PYTHONPATH"] = python_path + (
        os.pathsep + env["PYTHONPATH"] if env.get("PYTHONPATH") else ""
    )

    command = [sys.executable, str(source)]
    if expected_path is not None:
        result = capture_command(command, source.parent, input_path, env)
        return verify_result(result, expected_path) if result is not None else 1

    return finish_run(run_command(command, source.parent, input_path, env))


def main() -> int:
    parser = argparse.ArgumentParser(description="Compile and run CP source files.")
    parser.add_argument(
        "--new-cmd",
        action="store_true",
        help="Open a new cmd.exe window and run there.",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Compare stdout with expected.txt beside the source.",
    )
    parser.add_argument("source", help="Path to a .cpp, .java, or .py file")
    args = parser.parse_args()

    source = Path(args.source).resolve()
    root = Path(__file__).resolve().parents[1]

    if not source.is_file():
        print(f"Source is not a file: {source}", file=sys.stderr)
        return 1

    if args.new_cmd:
        return open_new_cmd(source, args.verify)

    try:
        input_path = selected_input(source)
        expected_path = source.parent / "expected.txt" if args.verify else None
        if expected_path is not None and not expected_path.is_file():
            label = "INVALID EXPECTED" if expected_path.exists() else "MISSING EXPECTED"
            failed(f"{label}: {expected_path}")
            return 1
        suffix = source.suffix.lower()

        if suffix == ".cpp":
            return run_cpp(source, root, input_path, expected_path)
        if suffix == ".java":
            return run_java(source, root, input_path, expected_path)
        if suffix == ".py":
            return run_python(source, root, input_path, expected_path)
    except OSError as exc:
        failed(f"EXECUTION ERROR: {exc}")
        return 1

    print(f"Unsupported file type: {source.suffix}", file=sys.stderr)
    print("Supported: .cpp, .java, .py", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
