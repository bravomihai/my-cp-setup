import argparse
import os
import random
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from subprocess import list2cmdline


GREEN = "\033[32m"
RED = "\033[31m"
RESET = "\033[0m"


def done() -> None:
    print(f"[{GREEN}DONE{RESET}]")


def failed(label: str) -> None:
    print(f"[{RED}{label}{RESET}]", file=sys.stderr)


def open_new_cmd(source: Path) -> int:
    if os.name != "nt":
        print("--new-cmd is only supported on Windows.", file=sys.stderr)
        return 1

    run_command_line = list2cmdline([sys.executable, str(Path(__file__).resolve()), str(source)])
    run_command_line = f"{run_command_line} & echo. & pause"
    subprocess.Popen(["cmd", "/c", "start", "", "/D", str(source.parent), "cmd", "/k", run_command_line])
    return 0


def selected_input(source: Path) -> Path | None:
    debug_input = source.parent / "debug" / "input.txt"
    local_input = source.parent / "input.txt"
    if debug_input.exists():
        return debug_input
    if local_input.exists():
        return local_input
    return None


def run_command(command: list[str], cwd: Path, input_path: Path | None = None, env: dict[str, str] | None = None) -> int:
    if input_path is None:
        return subprocess.run(command, cwd=cwd, env=env).returncode

    with input_path.open("rb") as stdin:
        return subprocess.run(command, cwd=cwd, stdin=stdin, env=env).returncode


def run_cpp(source: Path, root: Path, input_path: Path | None) -> int:
    exe = source.with_suffix(".exe")
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

    code = run_command([str(exe)], source.parent, input_path)
    if code != 0:
        failed("FAILED")
        return code
    done()
    return 0


def run_java(source: Path, root: Path, input_path: Path | None) -> int:
    build_dir = Path(tempfile.gettempdir()) / f"cp_java_{os.getpid()}_{random.randint(1000, 9999)}"
    build_dir.mkdir(parents=True, exist_ok=True)
    try:
        compile_cmd = [
            "javac",
            "-encoding",
            "UTF-8",
            "-cp",
            f"{root / 'libraries' / 'java'};{source.parent}",
            "-sourcepath",
            f"{root / 'libraries' / 'java'};{source.parent}",
            "-d",
            str(build_dir),
            str(source),
        ]
        if subprocess.run(compile_cmd, cwd=source.parent).returncode != 0:
            failed("COMPILE FAILED")
            return 1

        code = run_command(
            ["java", "-cp", f"{build_dir};{root / 'libraries' / 'java'}", source.stem],
            source.parent,
            input_path,
        )
        if code != 0:
            failed("FAILED")
            return code
        done()
        return 0
    finally:
        shutil.rmtree(build_dir, ignore_errors=True)


def run_python(source: Path, root: Path, input_path: Path | None) -> int:
    env = os.environ.copy()
    python_path = str(root / "libraries" / "python")
    env["PYTHONPATH"] = python_path + (os.pathsep + env["PYTHONPATH"] if env.get("PYTHONPATH") else "")

    code = run_command([sys.executable, str(source)], source.parent, input_path, env)
    if code != 0:
        failed("FAILED")
        return code
    done()
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Compile and run CP source files.")
    parser.add_argument("--new-cmd", action="store_true", help="Open a new cmd.exe window and run there.")
    parser.add_argument("source", help="Path to a .cpp, .java, or .py file")
    args = parser.parse_args()

    source = Path(args.source).resolve()
    root = Path(__file__).resolve().parents[1]

    if not source.exists():
        print(f"File not found: {source}", file=sys.stderr)
        return 1

    if args.new_cmd:
        return open_new_cmd(source)

    input_path = selected_input(source)
    suffix = source.suffix.lower()

    if suffix == ".cpp":
        return run_cpp(source, root, input_path)
    if suffix == ".java":
        return run_java(source, root, input_path)
    if suffix == ".py":
        return run_python(source, root, input_path)

    print(f"Unsupported file type: {source.suffix}", file=sys.stderr)
    print("Supported: .cpp, .java, .py", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
