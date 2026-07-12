# my-cp-setup

A Windows 11 competitive-programming workspace for C++, Java, and Python. It installs and configures the required tools, provides Neovim/LazyVim integration, reusable templates and helpers, command-line shortcuts, and submission expansion for all three languages.

For the complete day-to-day workflow, read the [usage guide](docs/usage.md).

## Highlights

- One `scripts\install.bat` installer for Git, Neovim, JDK, MSYS2, the C++ toolchain, Python, and `ac-library`.
- C++, Java, and Python templates with a small, consistent convenience layer.
- `scripts\run.py` to compile/run a solution and verify its output.
- `scripts\expand.py` to create a standalone submit file and copy it to the clipboard.
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

If the repository was cloned without submodules, initialize `ac-library` before installing:

```bat
git submodule update --init libraries/ac-library
scripts\install.bat
```

Normal installation updates `ac-library`; `--check` only reports whether an update is needed.

## Daily Workflow

1. Run `solve_cpp`, `solve_java`, or `solve_py` in a new Command Prompt. The macro creates the language directory if needed, copies its tracked template when `solve.*` is missing, and opens the untracked workspace copy without overwriting an existing solution.
2. Optionally put sample input in `input.txt` beside the source file with `<leader>i`; without it, the runner reads from the keyboard.
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
| `<leader>E` | Expand the current file and open `submit.<ext>` |
| `<leader>d` | Toggle diagnostics for the current buffer |

Normal runs keep solution output separate from their status with two blank lines and finish with `[DONE] 0.001234s`. Verification requires `expected.txt`, compares only stdout, reports stderr separately, and uses the same final `DONE` timer. The timer is emitted locally in the same six-decimal format by every template and is disabled in submissions.

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

The uninstaller keeps components that were detected before this setup installed them. It never deletes the tracked `nvim` configuration; removing Neovim can remove only generated local LazyVim data.

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

## Documentation

- [Usage guide](docs/usage.md): daily workflow, templates, keymaps, running, expansion, debugging, helpers, and CMD macros.
