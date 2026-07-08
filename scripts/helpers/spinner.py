import argparse
import subprocess
import sys
import time
from pathlib import Path


PURPLE = "\033[38;5;183m"
RESET = "\033[0m"
FRAMES = ["\\", "-", "/", "|"]


def main() -> int:
    parser = argparse.ArgumentParser(description="Run a command with a small console spinner.")
    parser.add_argument("--label", required=True)
    parser.add_argument("--cwd", default=str(Path.cwd()))
    parser.add_argument("--stdin-empty", action="store_true")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()

    command = args.command
    if command and command[0] == "--":
        command = command[1:]
    if not command:
        print("spinner.py: missing command", file=sys.stderr)
        return 1

    stdin = subprocess.DEVNULL if args.stdin_empty else None
    process = subprocess.Popen(
        command,
        cwd=args.cwd,
        stdin=stdin,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    index = 0
    while process.poll() is None:
        frame = FRAMES[index % len(FRAMES)]
        print(f"\r[{PURPLE}VERIFY{RESET}] {frame} {args.label}", end="", flush=True)
        time.sleep(0.1)
        index += 1

    stdout, stderr = process.communicate()
    if process.returncode == 0:
        print(f"\r[{PURPLE}VERIFY{RESET}] done {args.label}")
        return 0

    print(f"\r[{PURPLE}VERIFY{RESET}] failed {args.label}", file=sys.stderr)
    if stderr:
        print(stderr, file=sys.stderr, end="")
    if stdout:
        print(stdout, file=sys.stderr, end="")
    return process.returncode


if __name__ == "__main__":
    raise SystemExit(main())
