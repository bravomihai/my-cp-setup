# my-cp-setup

Personal **competitive programming setup** for C++ using **Neovim** and **VSCode**.

The repository provides scripts for:

- building and running C++ programs
- debugging with **GDB**
- expanding **AtCoder Library** together with personal headers into a single `submit.cpp` file ready for submission to online judges.

---

## Requirements

The following tools should be installed and available in `PATH`:

- `g++`
- `python`
- `gdb` *(only required for debugging)*
- `clang-format` *(optional, used for formatting)*
- `git` *(for cloning the repository and submodules)*

---

# Installation

### Clone the repository

```bash
git clone --recursive https://github.com/<user>/my-cp-setup.git
cd my-cp-setup
```

### If cloned without `--recursive`

```bash
git submodule update --init --recursive
```

### If downloaded as ZIP

Clone the AtCoder Library manually:

```bash
git clone https://github.com/atcoder/ac-library.git ac-library
```

---

# Repository Structure

```
my-cp-setup
├─ ac-library/            # AtCoder Library (git submodule)
├─ my_libraries/
│  ├─ cp.hpp              # personal helper header
│  └─ debug.cpp
├─ scripts/
│  ├─ expand_cpp.bat      # generates submit.cpp
│  ├─ build_run_cpp.bat   # compile and run helper
│  └─ debug_cpp.bat       # compile with debug symbols and start gdb
├─ nvim/
│  └─ init.lua            # Neovim configuration
├─ .vscode/               # VSCode tasks and settings
├─ template/
│  └─ solve.cpp           # template file for new problems
├─ .clang-format
├─ compile_flags.txt
├─ .gitignore
└─ README.md
```

---

# Scripts

All scripts receive **one argument**: the path to the C++ file.

---

## Expand

Generates a `submit.cpp` file containing:

- the source code
- `cp.hpp`
- expanded **AtCoder Library**

The result is also copied to the clipboard automatically.

```bat
scripts\expand_cpp.bat "D:\path\to\solve.cpp"
```

---

## Build and Run

Compiles with optimization and runs the program.

Input redirection is automatically selected in the following order:

1. `debug\input.txt`
2. `input.txt`
3. standard input

```bat
scripts\build_run_cpp.bat "D:\path\to\solve.cpp"
```

---

## Debug

Compiles with debug symbols and launches **gdb**.

```bat
scripts\debug_cpp.bat "D:\path\to\solve.cpp"
```

Scripts use **paths relative to the repository**, so the repository can be placed anywhere.

---

# Neovim Setup

The repository contains a complete `init.lua` configuration.

### Windows

```bash
mklink "%LOCALAPPDATA%\nvim\init.lua" "C:\path\to\my-cp-setup\nvim\init.lua"
```

### Linux / macOS

```bash
ln -s /path/to/my-cp-setup/nvim/init.lua ~/.config/nvim/init.lua
```

### Key Mappings

| Key | Action |
|----|----|
| `<leader>e` | expand source into `submit.cpp` |
| `<leader>r` | build and run |
| `<leader>d` | debug with gdb |

---

# VSCode Setup

The repository already contains configuration files.

If the `.vscode` folder is present in the repository root, **VSCode loads them automatically** when opening the project.

The tasks provide shortcuts for:

- build
- run
- expand
- debug

---

# Language Server Support

`compile_flags.txt` provides include paths for **clangd**.

```
-std=c++20
-I.
-Iac-library
-Imy_libraries
```

This allows editors to resolve includes such as:

```cpp
#include <atcoder/all>
#include <my_libraries/cp.hpp>
```

---

# Formatting

The repository includes a `.clang-format` file.

If `clang-format` is installed, editors and command line tools will automatically use this configuration.

---

# Minimal Usage

```bash
git clone --recursive https://github.com/bravomihai/my-cp-setup.git
cd my-cp-setup
scripts\expand_cpp.bat "path\to\solve.cpp"
scripts\build_run_cpp.bat "path\to\solve.cpp"
```