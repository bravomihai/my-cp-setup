# my-cp-setup

Personal competitive programming setup for Windows 11, with C++, Java, Python, Neovim, DOSKEY macros, and AtCoder Library expansion.

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
git submodule update --init libraries/ac-library
scripts\install.bat
```

## What The Installer Does

`scripts\install.bat` checks for:

- `git`
- `nvim`
- `javac`
- `g++`
- usable Python 3, preferring MSYS2 Python and ignoring the Microsoft Store `WindowsApps` alias

If a tool is missing, it tries to install it with `winget`. For C++ and Python, it installs MSYS2 externally and installs only the CP toolchain with `pacman`: GCC, GDB, clang tools, and Python.

The installer also:

- adds known tool directories to the user `Path`
- sets `XDG_CONFIG_HOME` to the repository root
- sets `CP_SETUP_ROOT` to the repository root
- sets `CP_PYTHON` to the real Python executable used by the setup
- configures CMD DOSKEY macros from `scripts\cp_macros`
- initializes the `ac-library` submodule
- verifies C++, Java, Python, and expansion for all three languages

External tools are not stored in this repository.

## Structure

```text
my-cp-setup
|-- libraries/
|   |-- ac-library/          AtCoder Library submodule
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
|   |-- cp_macros            CMD DOSKEY macros
|   |-- expand.py            Generate submit.cpp/submit.java/submit.py
|   |-- install.bat          Windows installer
|   `-- run.py               Run C++/Java/Python files
|-- template/
|   |-- cpp/solve.cpp
|   |-- java/solve.java
|   `-- python/solve.py
|-- .clang-format
|-- .clangd
|-- .gitignore
|-- .gitmodules
`-- README.md
```

## Build And Run

The runner compiles when needed and chooses input in this order:

1. `debug\input.txt`
2. `input.txt`
3. standard input

Examples:

```bat
"%CP_PYTHON%" scripts\run.py template\cpp\solve.cpp
"%CP_PYTHON%" scripts\run.py template\java\solve.java
"%CP_PYTHON%" scripts\run.py template\python\solve.py
```

## Expand

Generate a standalone submit file and copy it to the clipboard:

```bat
"%CP_PYTHON%" scripts\expand.py template\cpp\solve.cpp
"%CP_PYTHON%" scripts\expand.py template\java\solve.java
"%CP_PYTHON%" scripts\expand.py template\python\solve.py
```

On success it prints one of:

```text
[DONE] submit.cpp generated
[DONE] submit.java generated
[DONE] submit.py generated
```

Only `DONE` is green. On failure it prints an `EXPAND FAILED` message.

## CMD Macros

Install macro loading:

Use `scripts\install.bat`; macro loading is part of the installer.

New `cmd.exe` windows load these automatically after install.
The installer sets `HKCU\Software\Microsoft\Command Processor\AutoRun` to load `scripts\cp_macros` with `doskey /macrofile`.
The `run` and `expand` macros use `CP_PYTHON`, so they do not depend on the `python.exe` Microsoft Store alias. See `scripts\cp_macros` for the current macro list.

## Neovim

The installer sets `XDG_CONFIG_HOME` to the repository root. For example, if the repo was cloned to `C:\Users\mihai\my-cp-setup`, it sets:

```text
XDG_CONFIG_HOME=C:\Users\mihai\my-cp-setup
```

Neovim then loads the `nvim` folder inside that repository:

```text
<repo-root>\nvim
```

## Language Server

`.clangd` contains the C++ flags used by clangd:

```text
-std=c++20
-I.
-Ilibraries/ac-library
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
