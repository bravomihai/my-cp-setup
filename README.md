# my-cp-setup

Personal competitive programming setup for Windows 11, with C++, Java, Python, Neovim, DOSKEY macros, and AtCoder Library expansion.

## Quick Install

Clone anywhere you have write access and run the installer from the repository root:

```bat
git clone --recursive https://github.com/bravomihai/my-cp-setup.git my-cp-setup
cd /d my-cp-setup
scripts\install.bat
```

Preview the setup state without installing components or changing setup configuration:

```bat
scripts\install.bat --check
```

Show resolved executable paths during installation:

```bat
scripts\install.bat --verbose
```

If `--check` reports missing components, run the installer without `--check` to install them.
For `ac-library`, `--check` only reports whether the submodule needs an update; normal install updates it.

Interactively remove setup-managed external components and configuration:

```bat
scripts\uninstall.bat
```

Remove all setup-managed external components and configuration, then choose whether to remove the repository folder too:

```bat
scripts\uninstall.bat --all
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
- `ac-library` submodule state

If a tool is missing during a normal install, it tries to install it with `winget`. For C++ and Python, it installs MSYS2 and manages the CP toolchain through `pacman`. `--verbose` also shows the resolved executable paths after installation.

The installer also:

- adds and normalizes known tool directories in the user `Path`
- sets `XDG_CONFIG_HOME` to the repository root
- sets `CP_SETUP_ROOT` to the repository root
- sets `CP_PYTHON` to the real Python executable used by the setup
- adds its CMD DOSKEY macro command to `AutoRun` without replacing existing AutoRun commands
- initializes and updates the `ac-library` submodule
- verifies C++, Java, Python, and expansion for all three languages

The installer records external components it installs under the current-user registry key. Uninstall removes only those recorded components and reports detected pre-existing ones as `KEPT`.

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
|   |-- uninstall.bat        Uninstall setup-managed components and configuration
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

On success it reports the generated target file; on failure it prints an `EXPAND FAILED` message.

## Uninstall

When configuration cleanup is selected, `scripts\uninstall.bat` removes:

- known User `Path` entries managed by the setup
- `XDG_CONFIG_HOME`, `CP_SETUP_ROOT`, `CP_PYTHON`, and `CP_GPP` when they point to this setup or the known MSYS2 install paths
- its CMD AutoRun command for `scripts\cp_macros`, while preserving other commands

For a normal uninstall, it requests administrator rights once at startup, then asks before removing Git, Neovim, JDK, MSYS2, or the CP toolchain only when that component was recorded as installed by this setup. Detected pre-existing components are reported as `KEPT` without blocking repository-folder removal. Choosing Neovim removes only its local `nvim-data` directory (LazyVim, Mason, and downloaded plugins); this setup's tracked `nvim` configuration remains in the repository. If MSYS2 is kept and the CP toolchain was recorded as setup-managed, it separately asks whether to remove that toolchain. Components that are no longer registered with winget are kept and their stale setup records are cleared. The repository-folder prompt appears only when every offered removal and configuration cleanup was accepted.

`--all` removes setup-managed external components and configuration automatically, reports detected pre-existing components as `KEPT`, clears stale records without stopping the remaining cleanup, then asks whether to remove the repository folder. Each prompt displays `[Y/N]`; it accepts `y`, `ye`, `yes`, or `yeah` to confirm; `n`, `no`, or `nah` to decline, in any letter case.

Preview the uninstall state without running cleanup:

```bat
scripts\uninstall.bat --check
```

## CMD Macros

New `cmd.exe` windows load these automatically after installation.
The installer sets `HKCU\Software\Microsoft\Command Processor\AutoRun` to load `scripts\cp_macros` with `doskey /macrofile`.
The `run` and `expand` macros use `CP_PYTHON`, so they do not depend on the `python.exe` Microsoft Store alias. See `scripts\cp_macros` for the current macro list.

## Neovim

The installer sets `XDG_CONFIG_HOME` to the repository root, so Neovim loads `<repo-root>\nvim`. For example, if the repo was cloned to `C:\Users\mihai\my-cp-setup`, it sets:

```text
XDG_CONFIG_HOME=C:\Users\mihai\my-cp-setup
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
