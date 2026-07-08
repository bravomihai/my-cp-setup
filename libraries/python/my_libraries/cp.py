import sys
import time

_tokens = iter(sys.stdin.buffer.read().split())
_out = []
DEBUG = True


def token():
    return next(_tokens).decode()


def ni():
    return int(next(_tokens))


def nf():
    return float(next(_tokens))


def print_(*values, sep=" ", end="\n"):
    _out.append(sep.join(map(str, values)) + end)


def flush():
    sys.stdout.write("".join(_out))
    _out.clear()


def eprint(*values, sep=" ", end="\n"):
    print(*values, sep=sep, end=end, file=sys.stderr)


def out(*values, sep=" ", end="\n"):
    if DEBUG:
        eprint(*values, sep=sep, end=end)


class Timer:
    def __init__(self):
        self.start = time.perf_counter()

    def elapsed(self):
        return time.perf_counter() - self.start
