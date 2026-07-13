# my-cp-setup

A Windows 11 competitive-programming workspace for C++, Java, and Python. It installs and configures the required tools, provides Neovim/LazyVim integration, reusable templates and helpers, command-line shortcuts, and submission expansion for all three languages.

For the complete day-to-day workflow, read the [usage guide](docs/usage.md).

## Highlights

- One `scripts\install.bat` installer for Git, Neovim, Node.js/npm, JDK, MSYS2, the C++/Python toolchain, editor language tools, and `ac-library`.
- C++, Java, and Python templates with a small, consistent convenience layer.
- `scripts\run.py` to compile/run a solution and verify its output.
- `scripts\expand.py` to atomically create a standalone submit file and copy it to the clipboard.
- Neovim mappings for running, editing input/expected output, verifying, expanding submissions, and controlling diagnostics.
- An interactive uninstaller that removes only setup-managed components and configuration.

## Quick Start

Clone the repository with its submodule and run the installer from the repository root:

```bat
git clone --recursive https://github.com/bravomihai/my-cp-setup.git my-cp-setup
cd /d my-cp-setup
scripts\install.bat
```

Check the current setup without installing or changing configuration:

```bat
scripts\install.bat --check
```

Show the exact resolved executable paths while installing:

```bat
scripts\install.bat --verbose
```

Show the exact resolved executable paths during a read-only check:

```bat
scripts\install.bat --check --verbose
```

The scripts use only their own prompts and UAC flow; external package operations are silent and non-interactive. Actual installation and uninstallation must run from an account that belongs to the local Administrators group; the read-only `--check` modes do not require that membership. Existing tools are accepted when they satisfy the minimum versions: Python 3.10, Neovim 0.11, and both the Java compiler and runtime from JDK 21. The setup also ensures Node.js/npm, Ruff, the C++ toolchain, Pyright, JDT LS, Google Java Format, and clangd. Windows Package Manager (`winget`) is needed only when a missing or outdated winget-managed component must be installed or upgraded.

The setup adds to User PATH `scripts` plus only the directories of the exact Git, Neovim, Node.js/npm, JDK, C++, Python, and Ruff executables selected by the installer. Rerunning it removes obsolete setup-owned alternative JDK or MSYS2 toolchain directories while preserving unrelated and pre-existing PATH entries.

`ac-library` is fixed to the commit recorded by this repository. A Git clone initializes that exact submodule revision without following the remote branch; a source archive downloads the same pinned revision. `--check` reports a mismatch without changing it.

Verification uses isolated copies of all three templates in a unique temporary directory and never overwrites repository files or changes the clipboard. A read-only `--check` expands and compiles them without running them; a normal installation also runs each temporary template. The temporary directory is removed afterward.

## Daily Workflow

1. Run `solve_cpp`, `solve_java`, or `solve_py` in a new Command Prompt. The macro creates the language directory if needed, copies its tracked template when `solve.*` is missing, and opens the untracked workspace copy without overwriting an existing solution.
2. Optionally put sample input in `input.txt` beside the source file with `<leader>i`; without file input, the runner reads from the keyboard.
3. Run the current file from Neovim with `<leader>r`, or call `scripts\run.py` directly.
4. Put the expected output in `expected.txt` with `<leader>x`, then check it with `<leader>v`.
5. When the solution is ready, use `<leader>e` or `scripts\expand.py` to generate `submit.cpp`, `submit.java`, or `submit.py` in the same directory.

`<leader>` is `Space`. The most useful CP mappings are:

| Mapping | Action |
| --- | --- |
| `<leader>r` | Save and compile/run the current C++, Java, or Python file in a new `cmd.exe` window |
| `<leader>v` | Save, run, and verify stdout against `expected.txt` |
| `<leader>i` / `<leader>I` | Open input / clear and open input |
| `<leader>x` / `<leader>X` | Open expected output / clear and open expected output |
| `<leader>e` | Expand the current file and copy `submit.<ext>` to the clipboard |
| `<leader>E` | Expand and copy the current file, then open `submit.<ext>` |
| `<leader>d` | Toggle diagnostics for the current buffer |

Successful normal runs keep solution output separate from their status with two blank lines and finish with `[DONE] 0.001234s`. A completed verification comparison requires `expected.txt`, compares only stdout, reports stderr separately, and uses the same final `DONE` timer. The timer is emitted locally in the same six-decimal format by every template and is disabled in submissions.

C++ executables and Java classes are built in unique temporary directories and removed automatically. Verification enforces its five-second runtime limit when it uses file input; interactive keyboard input is not timed while you type.

Only the `workspace\cpp`, `workspace\java`, and `workspace\python` directory structure is tracked. Their solutions, input, expected output, generated submissions, and all other local contents remain ignored by Git.

See [docs/usage.md](docs/usage.md) for all custom mappings, runner behavior, expansion details, helpers, debugging conventions, and CMD macros.

## Maintenance

Run an interactive uninstall to choose which setup-managed components to remove:

```bat
scripts\uninstall.bat
```

Remove all setup-managed components and configuration, then choose whether to remove the repository folder:

```bat
scripts\uninstall.bat --all
```

Preview uninstall state without changing anything:

```bat
scripts\uninstall.bat --check
```

The installer records the environment values, PATH entries, packages, and Neovim data it actually creates. The uninstaller keeps pre-existing components and restores configuration only when the user has not changed the setup-written value afterward. It never deletes the tracked `nvim` configuration; generated `nvim-data` is removed in full only when it did not exist before installation, otherwise only exact setup-added Mason packages and the setup-created JDT LS workspace are removed.

## Project Layout

```text
my-cp-setup
|-- docs/                    Detailed user documentation
|-- libraries/
|   |-- ac-library/          AtCoder Library submodule
|   |-- cpp/my_libraries/    C++ helpers and debug output
|   |-- java/my_libraries/   Java helpers
|   `-- python/my_libraries/ Python helpers
|-- nvim/                    Neovim configuration
|-- scripts/                 Installer, uninstaller, runner, expander, CMD macros
|-- template/                C++, Java, and Python starter files
|-- workspace/               Tracked language folders; ignored local contents
|-- AGENTS.md                Guidance for coding agents
`-- README.md
```
