# Usage Guide

This guide explains the normal workflow after `scripts\install.bat` has completed successfully. The repository README covers installation and maintenance commands; this file covers solving problems.

## Start A Problem

Create a directory for the problem and copy the template for the language you want to use:

```text
problem/
|-- solve.cpp       or solve.java / solve.py
`-- debug/
    `-- input.txt
```

Use one of these templates as the starting point:

- `template\cpp\solve.cpp`
- `template\java\solve.java`
- `template\python\solve.py`

Each template already has a `solve` function, a single-test-case default, fast I/O setup where needed, and a local timing call through `out(...)`. Change `tc` only when the problem has multiple test cases.

`debug\input.txt` is the preferred local input file. The runner chooses input in this order:

1. `debug\input.txt`
2. `input.txt`
3. standard input

## Run A Solution

Run from the repository root with the configured Python executable:

```bat
"%CP_PYTHON%" scripts\run.py path\to\solve.cpp
"%CP_PYTHON%" scripts\run.py path\to\solve.java
"%CP_PYTHON%" scripts\run.py path\to\solve.py
```

For C++, the runner compiles with C++20, `-O2`, `libraries\cpp`, and `libraries\ac-library`, then runs the generated `.exe`. Java classes are compiled into a temporary directory and removed after the run. Python runs with `libraries\python` added to `PYTHONPATH`, so `from my_libraries.cp import *` works from any problem directory.

Add `--new-cmd` to run in a new `cmd.exe` window:

```bat
"%CP_PYTHON%" scripts\run.py --new-cmd path\to\solve.cpp
```

## Submit A Solution

Expand a source file when it is ready for an online judge:

```bat
"%CP_PYTHON%" scripts\expand.py path\to\solve.cpp
"%CP_PYTHON%" scripts\expand.py path\to\solve.java
"%CP_PYTHON%" scripts\expand.py path\to\solve.py
```

The generated file is written next to the source as `submit.cpp`, `submit.java`, or `submit.py`. When `clip.exe` is available, it is also copied to the Windows clipboard.

- **C++:** inserts the helper, defines `DISABLE_DEBUG` so `out(...)` is compiled out, then uses the AtCoder expander to inline `atcoder` headers.
- **Java:** inserts `Cp.java`, removes the local helper import, and changes `DEBUG` to `false`.
- **Python:** inserts `cp.py`, removes the local helper import, and changes `DEBUG` to `False`.

Do not submit the original file when it depends on `my_libraries`; submit the generated file instead.

## Neovim Workflow

`<leader>` is `Space`. The custom CP mappings work only in `.cpp`, `.java`, and `.py` buffers.

| Mapping | Action |
| --- | --- |
| `<leader>r` | Save and run the current file in a new `cmd.exe` window |
| `<leader>i` | Create or open `debug\input.txt` beside the current file |
| `<leader>e` | Save, expand, and copy `submit.<ext>` to the clipboard |
| `<leader>E` | Save, expand, and open `submit.<ext>` |
| `<leader>d` | Enable or disable diagnostics for the current buffer |

Other custom editing mappings:

| Mapping | Action |
| --- | --- |
| `jj` in Insert mode | Return to Normal mode |
| `gd` | Go to definition |
| `gr` | Show references |
| `K` | Show hover documentation |
| `<leader>cr` | Rename through the language server |
| `<leader>ca` | Show code actions |
| `<leader>cf` | Ask the active language server to format the buffer |
| `<leader><leader>` | Switch to the previously used buffer |
| `<leader>n` / `<leader>p` | Next / previous buffer |

Formatting depends on a formatter being available for that language. The configuration also keeps persistent undo, reserves the diagnostic sign column, uses an 8-line scroll offset, and disables soft wrapping for C, C++, Java, and Python buffers.

## Templates And Helpers

The local helper libraries deliberately contain only common contest conveniences. Keep larger algorithms and data structures in problem code or a separate library.

### C++

`template\cpp\solve.cpp` includes:

```cpp
#include <my_libraries/cp.hpp>
#include <atcoder/all>
```

`cp.hpp` provides common aliases, loop/input/output macros, ordered-set aliases, constants, and local debug support. Use normal `cout` for answers. Use `out(...)` for diagnostics: it writes to standard error locally and is compiled out when either `DISABLE_DEBUG` or `ONLINE_JUDGE` is defined. The expansion script defines `DISABLE_DEBUG` explicitly; `ONLINE_JUDGE` remains a fallback when unexpanded source is submitted.

### Java

`template\java\solve.java` imports `my_libraries.Cp`. Use:

- `Cp.fs` for fast token input, including array and matrix helpers.
- `Cp.print(...)` and `Cp.println(...)` for buffered standard output, followed by `Cp.flush()`.
- `Cp.out(...)` for debug output on standard error.
- `Cp.yn(...)`, `Cp.min3(...)`, `Cp.max3(...)`, `Cp.inside(...)`, `Cp.Timer`, and common constants.

Keep the public class name aligned with the source filename when changing the template name.

### Python

`template\python\solve.py` imports everything from `my_libraries.cp`. Use:

- `token()`, `ni()`, `nf()`, `nints(n)`, `ntokens(n)`, and `read_grid(n)` for input.
- `print_(...)`, `print_iter(...)`, and `flush()` for buffered standard output.
- `out(...)` or `eprint(...)` for diagnostics on standard error.
- `yn(...)`, `min3(...)`, `max3(...)`, `inside(...)`, `Timer`, and common constants.

`out(...)` is enabled during local work. Java and Python expansion disable it automatically in the generated submit file.

## Debugging Conventions

Keep answer output separate from diagnostics:

- C++: `cout` for answers and `out(...)` for debug information.
- Java: `Cp.print` / `Cp.println` plus `Cp.flush()` for answers, and `Cp.out(...)` for debug information.
- Python: `print_` / `print_iter` plus `flush()` for answers, and `out(...)` or `eprint(...)` for debug information.

The templates print elapsed time through the debug channel after producing normal output. This helps local testing without contaminating standard output.

## CMD Macros

The installer configures new `cmd.exe` windows to load `scripts\cp_macros`. Open a new Command Prompt after installation to use these macros:

| Macro | Action |
| --- | --- |
| `cp` or `cpsetup` | Change to the setup root |
| `solve_cpp` | Open the C++ template in Neovim |
| `solve_java` | Open the Java template in Neovim |
| `solve_py` | Open the Python template in Neovim |
| `input` | Open `<setup-root>\input.txt` in Neovim |
| `run <file>` | Call `scripts\run.py` for a source file |
| `expand <file>` | Call `scripts\expand.py` for a source file |

The `run` and `expand` macros use `CP_PYTHON`, so they avoid the Microsoft Store Python alias.

## Verify And Maintain

Check that the full setup works without making changes:

```bat
scripts\install.bat --check
```

Use `scripts\install.bat --verbose` during a normal install when you need the exact paths of resolved tools. For cleanup, use `scripts\uninstall.bat` interactively, `scripts\uninstall.bat --all` for setup-managed components and configuration, or `scripts\uninstall.bat --check` for a dry check.
