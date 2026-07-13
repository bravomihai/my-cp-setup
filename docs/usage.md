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

Each template already has a `solve` function, a single-test-case default, fast I/O setup where needed, and a local timer that writes seconds with six decimal places, such as `0.001234s`. Change `tc` only when the problem has multiple test cases.

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

For C++, the runner compiles with C++20, `-O2`, `libraries\cpp`, and `libraries\ac-library`. Both the C++ executable and Java classes are built in unique temporary directories and removed after the run. Python runs with `libraries\python` added to `PYTHONPATH`, so `from my_libraries.cp import *` works from any problem directory.

The configured `CP_GPP`, `CP_JAVAC`, and `CP_JAVA` paths select the exact C++ compiler, Java compiler, and matching Java runtime found by the installer, even if unrelated older tools appear earlier in the system PATH. Python runs with bytecode generation disabled, so importing the helper does not leave `__pycache__` inside the repository.

The installer adds only the directories containing those selected tools, Git, Neovim, Node.js/npm, and Ruff to User PATH; it does not add every detected JDK or both MSYS2 toolchain variants.

A successful normal run puts two blank lines between solution output and runner status. Any local diagnostics appear immediately before `DONE`:

```text
solution output


[DONE] 0.001234s
```

Add `--new-cmd` to run in a new `cmd.exe` window:

```bat
"%CP_PYTHON%" scripts\run.py --new-cmd path\to\solve.cpp
```

Add `--verify` to compare the program's standard output with `expected.txt` beside the source. `expected.txt` is required; file input is optional, and the program reads interactively when neither `input.txt` nor the legacy fallback exists. Diagnostics written to standard error are displayed separately and never enter the comparison. The template timer is extracted from stderr and displayed after two blank lines:

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

Here `-1` and `+1` both refer to line 1 in their respective files; they are not character counts. A line prefixed with `-` came from `expected.txt`, while a line prefixed with `+` came from the program. Line endings, one optional final newline, and trailing whitespace are ignored; line order and internal spaces remain significant. Runtime errors, a missing `expected.txt`, and the five-second timeout have distinct messages. Runtime errors and timeouts stop before comparison and do not print a final `DONE` line. The timeout applies when input comes from a file; interactive verification waits without counting the time spent typing.

## Submit A Solution

Expand a source file when it is ready for an online judge:

```bat
"%CP_PYTHON%" scripts\expand.py path\to\solve.cpp
"%CP_PYTHON%" scripts\expand.py path\to\solve.java
"%CP_PYTHON%" scripts\expand.py path\to\solve.py
```

The generated file is written next to the source as `submit.cpp`, `submit.java`, or `submit.py`. When `clip.exe` is available, it is also copied to the Windows clipboard.

Generation is atomic: a failed expansion leaves any previous submit file unchanged. Pass `--no-clipboard` when the generated file should not replace the current clipboard contents.

- **C++:** inserts the helper, defines `DISABLE_DEBUG` so `out(...)` is compiled out, then uses the AtCoder expander to inline `atcoder` headers.
- **Java:** hoists and deduplicates imports, inserts `Cp.java`, removes package/local-helper declarations, changes `DEBUG` to `false`, and renames the top-level public source class and references to its name to `Main`.
- **Python:** preserves the shebang, encoding cookie, module docstring, and `from __future__` imports before inserting `cp.py`; it removes the local helper import and changes `DEBUG` to `False`.

Do not submit the original file when it depends on `my_libraries`; submit the generated file instead.

For Java, use `import my_libraries.Cp` and qualify helper calls as `Cp.member(...)`. Static imports from `my_libraries.Cp` are rejected explicitly because they cannot remain valid after the helper is inlined into the judge's default package.

For Python, helper imports must be top-level, unaliased `from my_libraries.cp import ...` statements. Qualified, aliased, or nested helper imports are rejected explicitly so a failed expansion cannot produce a broken submission.

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
| `<leader>E` | Save and expand as above, then open `submit.<ext>` |
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

Saving supported source files formats them first when the formatter is available: Ruff for Python, Google Java Format for Java, and the language server for C/C++. `<leader>cf` triggers formatting manually. Completion popups are intentionally disabled, while LSP navigation and code actions remain available. The configuration also keeps persistent undo, reserves the diagnostic sign column, uses an 8-line scroll offset, and disables soft wrapping for C, C++, Java, and Python buffers. Leaving a buffer autosaves only C++, Java, Python, `input.txt`, and `expected.txt` files.

Saving a Python or Java buffer also runs a syntax check without executing the solution. Python uses Ruff in syntax-only mode, while Java uses `javac` with the local helper library and writes generated classes to a unique temporary cache directory that is cleaned after each check. Errors appear as inline diagnostics on the relevant line and can be hidden or restored with `<leader>d`. Pyright and JDT LS provide hover, definition, reference, rename, and code-action support for Python and Java.

## Templates And Helpers

### C++

`template\cpp\solve.cpp` includes:

```cpp
#include <my_libraries/cp.hpp>
#include <atcoder/all>
```

`cp.hpp` provides common aliases, loop/input/output macros, ordered sets, constants, and local debug support. Use normal `cout` for answers. Use `out(...)` for diagnostics: it writes to standard error locally and is compiled out when either `DISABLE_DEBUG` or `ONLINE_JUDGE` is defined. The expansion script defines `DISABLE_DEBUG` explicitly; `ONLINE_JUDGE` remains a fallback when unexpanded source is submitted.

`oset<T>` and `oset_desc<T>` are unique-value PBDS trees. `omset<T>` and `omset_desc<T>` are duplicate-safe wrappers backed by `(value, unique_id)` keys and provide `insert`, `erase_one`, `erase_all`, `count`, `contains`, `order_of_key`, `find_by_order`, `size`, `empty`, and `clear`. `find_by_order` returns `std::optional<T>`; for descending sets, order zero is the largest value.

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

`out(...)` and `eprint(...)` are enabled only during local Python work. `Cp.out(...)` and `Cp.err(...)` follow the same rule in Java. `timer_out(...)` in Python and C++, plus `Cp.timerOut(...)` in Java, provide the templates' consistent six-decimal timing line. Expansion disables all these local diagnostics automatically in the generated submit file.

## Debugging Conventions

Keep answers on standard output and diagnostics on standard error: use `cout` / `out(...)` in C++, `Cp.print` or `Cp.println` / `Cp.out(...)` in Java, and `print_` or `print_iter` / `out(...)` or `eprint(...)` in Python. Flush the buffered Java and Python answer output before timing. The templates print elapsed time through the debug channel, so neither diagnostics nor timers contaminate judged output.

## CMD Macros

The installer configures new `cmd.exe` windows to load `scripts\cp_macros`. Open a new Command Prompt after installation to use these macros:

| Macro | Action |
| --- | --- |
| `cp` or `cpsetup` | Change to the setup root |
| `solve_cpp` | Create if needed and open `workspace\cpp\solve.cpp` |
| `solve_java` | Create if needed and open `workspace\java\solve.java` |
| `solve_py` | Create if needed and open `workspace\python\solve.py` |
| `input` | Open the legacy root-level `input.txt` in Neovim |
| `run <file>` | Call `scripts\run.py` for a source file |
| `expand <file>` | Call `scripts\expand.py` for a source file |

The `run` and `expand` macros use `CP_PYTHON`, so they avoid the Microsoft Store Python alias.

## Verify The Setup

Check that the full setup works without making changes:

```bat
scripts\install.bat --check
```

Add `--verbose` to the check when you need the exact resolved tool and PATH locations:

```bat
scripts\install.bat --check --verbose
```

The check expands and compiles temporary copies of all templates without running them, changing the clipboard, or writing generated files into the repository. See the [repository README](../README.md#maintenance) for installation and cleanup behavior.
