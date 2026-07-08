import sys
import time

_tokens = None
_out = []
DEBUG = True


def _get_tokens():
    global _tokens
    if _tokens is None:
        _tokens = iter(sys.stdin.buffer.read().split())
    return _tokens


def token():
    return next(_get_tokens()).decode()


def ni():
    return int(next(_get_tokens()))


def nf():
    return float(next(_get_tokens()))


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
