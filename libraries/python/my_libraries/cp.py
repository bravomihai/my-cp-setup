import sys
import time

_tokens = None
_out = []
DEBUG = True
MOD_CONST = 998_244_353
INF = sys.maxsize
NR1E5 = 100_000
NR1E9 = 1_000_000_000


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


def nints(n):
    return [ni() for _ in range(n)]


def ntokens(n):
    return [token() for _ in range(n)]


def read_grid(n):
    return [token() for _ in range(n)]


def yn(value):
    print_("Yes" if value else "No")


def min3(a, b, c):
    return min(a, b, c)


def max3(a, b, c):
    return max(a, b, c)


def inside(x, y, height, width):
    return 0 <= x < height and 0 <= y < width


def print_(*values, sep=" ", end="\n"):
    _out.append(sep.join(map(str, values)) + end)


def print_iter(values, sep=" ", end="\n"):
    _out.append(sep.join(map(str, values)) + end)


def flush():
    sys.stdout.write("".join(_out))
    _out.clear()


def eprint(*values, sep=" ", end="\n"):
    if DEBUG:
        print(*values, sep=sep, end=end, file=sys.stderr)


def out(*values, sep=" ", end="\n"):
    eprint(*values, sep=sep, end=end)


def timer_out(seconds):
    if DEBUG:
        eprint(f"{seconds:.6f}s")


class Timer:
    def __init__(self):
        self.start = time.perf_counter()

    def elapsed(self):
        return time.perf_counter() - self.start
