# Usage Guide

This guide explains the normal workflow after `scripts\install.bat` has completed successfully. The repository README covers installation and maintenance commands; this file covers solving problems.

## Start A Problem

Use the untracked local workspace for the solution you are currently solving:

```text
workspace/
|-- cpp/                     solve.cpp, input.txt, expected.txt
|-- java/                    solve.java, input.txt, expected.txt
`-- python/                  solve.py, input.txt, expected.txt
```

The `solve_cpp`, `solve_java`, and `solve_py` CMD macros create the corresponding language directory if needed, copy the template only when the workspace solution is missing, and then open the workspace file. Existing solutions are never overwritten. The sources are:

- `template\cpp\solve.cpp`
- `template\java\solve.java`
- `template\python\solve.py`

Each template already has a `solve` function, a single-test-case default, fast I/O setup where needed, and a local timing call that consistently writes `0.001234s` with six decimals. Change `tc` only when the problem has multiple test cases.

Git tracks an empty placeholder in each language directory so the workspace structure exists after cloning. Every other file below `workspace` is ignored. It intentionally keeps only one mutable solution per language; delete a solution when you want its pristine template recreated. The runner chooses input in this order:

1. `input.txt` beside the solution
2. `debug\input.txt` beside the solution (legacy fallback)
3. standard input

## Run A Solution

Run from the repository root with the configured Python executable:

```bat
"%CP_PYTHON%" scripts\run.py path\to\solve.cpp
"%CP_PYTHON%" scripts\run.py path\to\solve.java
"%CP_PYTHON%" scripts\run.py path\to\solve.py
```

For C++, the runner compiles with C++20, `-O2`, `libraries\cpp`, and `libraries\ac-library`, then runs the generated `.exe`. Java classes are compiled into a temporary directory and removed after the run. Python runs with `libraries\python` added to `PYTHONPATH`, so `from my_libraries.cp import *` works from any problem directory.

Normal output is followed by two blank lines and the runner status. Any local diagnostics appear immediately before `DONE`:

```text
solution output


[DONE] 0.001234s
```

Add `--new-cmd` to run in a new `cmd.exe` window:

```bat
"%CP_PYTHON%" scripts\run.py --new-cmd path\to\solve.cpp
```

Add `--verify` to compare the program's standard output with `expected.txt` beside the source. `expected.txt` is required; `input.txt` is optional, and without it the program reads interactively from the keyboard. Diagnostics written to standard error are displayed separately and never enter the comparison. The template timer is extracted from stderr and displayed after two blank lines:

```text
[PASS]
[STDERR EMPTY]


[DONE] 0.001234s
```

When diagnostics exist, `[STDERR EMPTY]` becomes `[STDERR]` followed by their content. A mismatch reports the first differing line and column and includes a unified diff:

```diff
--- expected.txt
+++ program output
@@ -1 +1 @@
-Hello, Worl!
+Hello, World!
```

Here `-1` and `+1` both refer to line 1 in their respective files; they are not character counts. A line prefixed with `-` came from `expected.txt`, while a line prefixed with `+` came from the program. Line endings, one optional final newline, and trailing whitespace are ignored; line order and internal spaces remain significant. Runtime errors, a missing `expected.txt`, and the five-second timeout have distinct messages.

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

`<leader>` is `Space`. Run, verify, and expansion require a `.cpp`, `.java`, or `.py` buffer. Input and expected-output mappings use the current buffer's directory regardless of file type, or Neovim's current directory for an unnamed buffer.

| Mapping | Action |
| --- | --- |
| `<leader>r` | Save and run the current file in a new `cmd.exe` window |
| `<leader>v` | Save, run, and verify stdout against `expected.txt` |
| `<leader>i` | Create or open `input.txt` beside the current file |
| `<leader>I` | Clear and open `input.txt` (undo is available before saving) |
| `<leader>x` | Create or open `expected.txt` beside the current file |
| `<leader>X` | Clear and open `expected.txt` (undo is available before saving) |
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
| `<leader>cf` | Format with Ruff for Python, Google Java Format for Java, or the language server as fallback |
| `<leader><leader>` | Switch to the previously used buffer |
| `<leader>n` / `<leader>p` | Next / previous buffer |

Formatting depends on a formatter being available for that language. The configuration also keeps persistent undo, reserves the diagnostic sign column, uses an 8-line scroll offset, and disables soft wrapping for C, C++, Java, and Python buffers.

Saving a Python or Java buffer also runs a syntax check without executing the solution. Python uses Ruff in syntax-only mode, while Java uses `javac` with the local helper library and writes generated classes to Neovim's cache. Errors appear as inline diagnostics on the relevant line and can be hidden or restored with `<leader>d`. Pyright and JDT LS provide hover, definition, reference, rename, and code-action support for Python and Java.

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

`out(...)` is enabled during local work. `timer_out(...)` in Python and C++, plus `Cp.timerOut(...)` in Java, provide the templates' consistent six-decimal timing line. Expansion disables these local diagnostics automatically in the generated submit file.

## Debugging Conventions

Keep answer output separate from diagnostics:

- C++: `cout` for answers and `out(...)` for debug information.
- Java: `Cp.print` / `Cp.println` plus `Cp.flush()` for answers, and `Cp.out(...)` for debug information.
- Python: `print_` / `print_iter` plus `flush()` for answers, and `out(...)` or `eprint(...)` for debug information.

The templates print elapsed time as `0.001234s` through the debug channel after producing normal output. This helps local testing without contaminating standard output.

## CMD Macros

The installer configures new `cmd.exe` windows to load `scripts\cp_macros`. Open a new Command Prompt after installation to use these macros:

| Macro | Action |
| --- | --- |
| `cp` or `cpsetup` | Change to the setup root |
| `solve_cpp` | Create if needed and open `workspace\cpp\solve.cpp` |
| `solve_java` | Create if needed and open `workspace\java\solve.java` |
| `solve_py` | Create if needed and open `workspace\python\solve.py` |
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
