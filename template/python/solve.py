from my_libraries.cp import *


def solve():
    print_("Hello, World!")


#   /\_/\
#  (= ._.)
#  / >  \>


def main():
    timer = Timer()

    tc = 1  # tc = ni()
    for _ in range(tc):
        solve()

    flush()
    out("\n")
    out(f"{timer.elapsed():.6f}s")


if __name__ == "__main__":
    main()
