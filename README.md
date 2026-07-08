# my-cp-setup

Personal competitive programming setup for Windows 11, with C++, Java, Python, Neovim, VS Code tasks, DOSKEY macros, and AtCoder Library expansion.

## Quick Install

Clone anywhere you have write access and run the installer from the repository root:

```bat
git clone --recursive https://github.com/bravomihai/my-cp-setup.git my-cp-setup
cd /d my-cp-setup
scripts\install.bat
```

Verify without changing environment variables:

```bat
scripts\install.bat --check
```

If you cloned without submodules:

```bat
git submodule update --init ac-library
scripts\install.bat
```

## What The Installer Does

`scripts\install.bat` checks for:

- `git`
- `nvim`
- `python`
- `javac`
- `g++`

If a tool is missing, it tries to install it with `winget`. For C++, it installs MSYS2 externally and installs the needed toolchain with `pacman`.

The installer also:

- adds known tool directories to the user `Path`
- sets `XDG_CONFIG_HOME` to the repository root
- configures CMD DOSKEY macros from `cmd\cmd_macros.txt`
- initializes the `ac-library` submodule
- verifies C++, Java, Python, and C++ expansion

External tools are not stored in this repository.

## Structure

```text
my-cp-setup
|-- ac-library/              AtCoder Library submodule
|-- cmd/
|   `-- cmd_macros.txt       CMD DOSKEY macros
|-- libraries/
|   |-- cpp/
|   |   `-- my_libraries/
|   |       |-- cp.hpp       C++ helpers
|   |       `-- debug.cpp    C++ debug output helpers
|   |-- java/
|   |   `-- my_libraries/
|   |       `-- Cp.java      Java helpers
|   `-- python/
|       `-- my_libraries/
|           `-- cp.py        Python helpers
|-- nvim/                    Neovim configuration
|-- scripts/
|   |-- debug_cpp.bat        Compile C++ with debug symbols and run gdb
|   |-- expand.py            Generate submit.cpp/submit.java/submit.py
|   |-- install.bat          Windows installer
|   |-- install_cmd_macros.bat
|   `-- install_paths.ps1
|   `-- run.py               Run C++/Java/Python files
|-- template/
|   |-- cpp/solve.cpp
|   |-- java/solve.java
|   `-- python/solve.py
|-- vscode/                  VS Code tasks/settings
|-- .clang-format
|-- .gitignore
|-- .gitmodules
|-- compile_flags.txt
`-- README.md
```

## Build And Run

The runner compiles when needed and chooses input in this order:

1. `debug\input.txt`
2. `input.txt`
3. standard input

Examples:

```bat
python scripts\run.py template\cpp\solve.cpp
python scripts\run.py template\java\solve.java
python scripts\run.py template\python\solve.py
```

## Expand C++

Generate a standalone submit file and copy it to the clipboard:

```bat
python scripts\expand.py template\cpp\solve.cpp
python scripts\expand.py template\java\solve.java
python scripts\expand.py template\python\solve.py
```

On success it prints one of:

```text
[DONE] submit.cpp generated
[DONE] submit.java generated
[DONE] submit.py generated
```

Only `DONE` is green. On failure it prints an `EXPAND FAILED` message.

## Debug C++

```bat
scripts\debug_cpp.bat template\cpp\solve.cpp
```

## CMD Macros

Install macro loading:

```bat
scripts\install_cmd_macros.bat
```

Available macros:

```text
cp
cpsetup
solve_cpp
solve_java
solve_py
input
run
expand
debug
```

New `cmd.exe` windows load these automatically after install.

## Neovim

The installer sets `XDG_CONFIG_HOME` to the repository root. For example, if the repo was cloned to `C:\Users\mihai\my-cp-setup`, it sets:

```text
XDG_CONFIG_HOME=C:\Users\mihai\my-cp-setup
```

Neovim then loads the `nvim` folder inside that repository:

```text
<repo-root>\nvim
```

## VS Code

The `vscode` directory contains optional tasks/settings that can be copied or symlinked into `.vscode` if desired. The main runner is `scripts\run.py`.

## Language Server

`compile_flags.txt` contains:

```text
-std=c++20
-I.
-Iac-library
-Ilibraries/cpp
```

This supports C++ includes such as:

```cpp
#include <atcoder/all>
#include <my_libraries/cp.hpp>
```

Java and Python templates keep their imports stable:

```java
import static my_libraries.Cp.*;
```

```python
from my_libraries.cp import *
```
