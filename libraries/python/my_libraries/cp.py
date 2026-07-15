import builtins as _builtins
import sys
import time

DEBUG = True
MOD_CONST = 998_244_353
INF = sys.maxsize
NR1E5 = 100_000
NR1E9 = 1_000_000_000


def _build_helpers(debug, system, clock, base):
    tokens = None
    buffered_output = []

    def get_tokens():
        nonlocal tokens
        if tokens is None:
            tokens = base.iter(system.stdin.buffer.read().split())
        return tokens

    def token():
        return base.next(get_tokens()).decode()

    def ni():
        return base.int(base.next(get_tokens()))

    def nf():
        return base.float(base.next(get_tokens()))

    def nints(n):
        return [ni() for _ in base.range(n)]

    def ntokens(n):
        return [token() for _ in base.range(n)]

    def read_grid(n):
        return [token() for _ in base.range(n)]

    def print_(*values, sep=" ", end="\n"):
        buffered_output.append(sep.join(base.map(base.str, values)) + end)

    def print_iter(values, sep=" ", end="\n"):
        buffered_output.append(sep.join(base.map(base.str, values)) + end)

    def flush():
        system.stdout.write("".join(buffered_output))
        buffered_output.clear()

    def yn(value):
        print_("Yes" if value else "No")

    def min3(a, b, c):
        return base.min(a, b, c)

    def max3(a, b, c):
        return base.max(a, b, c)

    def inside(x, y, height, width):
        return 0 <= x < height and 0 <= y < width

    def eprint(*values, sep=" ", end="\n"):
        if debug:
            base.print(*values, sep=sep, end=end, file=system.stderr)

    def out(*values, sep=" ", end="\n"):
        eprint(*values, sep=sep, end=end)

    def timer_out(seconds):
        if debug:
            eprint(f"{seconds:.6f}s")

    class Timer:
        def __init__(self):
            self.start = clock.perf_counter()

        def elapsed(self):
            return clock.perf_counter() - self.start

    helpers = (
        get_tokens,
        token,
        ni,
        nf,
        nints,
        ntokens,
        read_grid,
        yn,
        min3,
        max3,
        inside,
        print_,
        print_iter,
        flush,
        eprint,
        out,
        timer_out,
        Timer,
    )
    get_tokens.__name__ = "_get_tokens"
    for helper in helpers:
        helper.__qualname__ = helper.__name__
    return helpers


(
    _get_tokens,
    token,
    ni,
    nf,
    nints,
    ntokens,
    read_grid,
    yn,
    min3,
    max3,
    inside,
    print_,
    print_iter,
    flush,
    eprint,
    out,
    timer_out,
    Timer,
) = _build_helpers(DEBUG, sys, time, _builtins)
del _build_helpers
