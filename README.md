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

If `--check` reports missing components, run the installer without `--check` to install them.

Remove only the environment entries added by this setup:

```bat
scripts\uninstall.bat
```

If you cloned without submodules:

```bat
git submodule update --init libraries/ac-library
scripts\install.bat
```

## What The Installer Does

`scripts\install.bat` checks for:

- `git`, needed for the `ac-library` submodule
- `nvim`
- `javac`
- `g++`
- usable Python 3, preferring MSYS2 Python and ignoring the Microsoft Store `WindowsApps` alias

If a tool is missing during a normal install, it tries to install it with `winget`. Existing Git is kept silent during normal installs; if Git is missing, the installer shows it like the other install steps. For C++ and Python, it installs MSYS2 externally and installs only the CP toolchain with `pacman`: GCC, GDB, clang tools, and Python.

The installer also:

- adds and normalizes known tool directories in the user `Path`
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
|   |-- uninstall.bat        Remove environment entries added by setup
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

From Neovim, `<leader>r` calls `scripts\run.py --new-cmd` and opens the result in a new `cmd.exe` window.

## Expand

Generate a standalone submit file and copy it to the clipboard:

```bat
"%CP_PYTHON%" scripts\expand.py template\cpp\solve.cpp
"%CP_PYTHON%" scripts\expand.py template\java\solve.java
"%CP_PYTHON%" scripts\expand.py template\python\solve.py
```

On success it prints one of:

```text
submit.cpp generated
submit.java generated
submit.py generated
```

On failure it prints an `EXPAND FAILED` message.

## Uninstall

`scripts\uninstall.bat` removes only entries managed by this setup:

- known User `Path` entries added by the installer
- `XDG_CONFIG_HOME`, `CP_SETUP_ROOT`, `CP_PYTHON`, and `CP_GPP` when they point to this setup or the known MSYS2 install paths
- CMD AutoRun for `scripts\cp_macros`

It does not uninstall external tools such as Neovim, JDK, MSYS2, or Git.

Preview without changing anything:

```bat
scripts\uninstall.bat --check
```

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
