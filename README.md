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

Write the complete installation transcript to a chosen file:

```bat
scripts\install.bat --log C:\path\to\install.log
```

For automation, start from an already elevated terminal:

```bat
scripts\install.bat --non-interactive
```

This mode does not open a UAC prompt and fails when the terminal is not already elevated.

The scripts use only their own prompts and UAC flow; external package operations are silent and non-interactive. A normal installation or uninstallation requests administrator rights once when needed. Machine components and protected ownership state use the elevated token, while profile, User registry, Neovim data, and repository operations use the invoking user's standard token. This remains true if UAC credentials belong to a different administrator. Setup state is protected in the machine registry and kept separately for the invoking account's SID. The read-only `--check` modes do not elevate.

The elevated child exits automatically. The original window reports the final statuses and returns the child's real exit code; UAC cancellation, failure, and timeout are nonzero. A complete transcript is retained as `%LOCALAPPDATA%\Temp\cp_setup_install.log` by default, or at the path selected with `--log`. Long-running child processes are terminated as a process tree when their finite watchdog expires.

Existing protected tools are accepted when Python is 3.10 or newer, Neovim is 0.11 or newer, Node.js reports an LTS release, npm runs successfully, and both the Java compiler and runtime are from JDK 21 or newer. Node.js and npm are required by Pyright and Neovim language tooling. Candidate tool executables used by privileged operations must come from protected machine locations; setup installs or selects a protected copy instead of trusting one from a user-writable directory. Across elevation, the repository batch source stays locked against replacement while its final path, content hash, and bytes are read from the same handle. Only a newly created copy in the protected runtime is executed by the elevated child; the original path is not reopened. The setup also ensures Ruff, the C++ toolchain, Pyright, JDT LS, Google Java Format, and clangd. Windows Package Manager (`winget`) is required when a missing or outdated winget-managed component must be installed or upgraded, and when uninstalling or verifying a setup-owned winget package. Those packages are managed in machine scope, so the administrator account used for UAC must have a working WinGet registration when package work is required.

Neovim plugin and language-tool phases use their own shorter deadlines; Mason reports the current language tool as `N/4` and stops immediately on an error. Rerunning the installer can repair a stale Mason launcher left by an interrupted older installation.

The setup adds to User PATH `scripts` plus only the directories of the exact Git, Neovim, Node.js/npm, JDK, C++, Python, and Ruff executables selected by the installer. Rerunning it removes obsolete setup-owned alternative JDK or MSYS2 toolchain directories while preserving unrelated and pre-existing PATH entries.

`ac-library` is fixed to the commit recorded by this repository. A Git clone initializes that exact submodule revision without following the remote branch; a source archive downloads the same pinned revision. Its initial check reports `UP TO DATE` when the pinned tree is already present. Missing copies are installed and setup-managed stale source-archive copies are updated through a verified staging tree; unknown or locally modified contents are preserved and rejected. Success is reported only after a silent final integrity check. `--check` reports a mismatch without changing it.

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

See [docs/usage.md](docs/usage.md) for all project-specific mappings, runner behavior, expansion details, helpers, debugging conventions, and CMD macros.

## Maintenance

Run an interactive uninstall to choose which setup-managed components to remove:

```bat
scripts\uninstall.bat
```

Remove all setup-managed components and configuration, then choose whether to remove the repository folder:

```bat
scripts\uninstall.bat --all
```

For automation, run from an already elevated terminal and remove all managed components and configuration while keeping the repository:

```bat
scripts\uninstall.bat --non-interactive
```

Use `--log C:\path\to\uninstall.log` to choose the complete uninstall transcript destination. Otherwise it is retained as `%LOCALAPPDATA%\Temp\cp_setup_uninstall.log`. Neither script waits for a final key press.

Preview uninstall state without changing anything:

```bat
scripts\uninstall.bat --check
```

The installer records, in protected per-SID state, immutable pre-install snapshots plus the environment values, PATH entries, packages, Neovim data, and temporary artifacts it actually creates. Interrupted installs can be retried without reclassifying setup-created data as pre-existing. The uninstaller keeps pre-existing components and restores configuration only when the user has not changed the setup-written value afterward. It never deletes the tracked `nvim` configuration; generated `nvim-data` is removed in full only when it did not exist before installation, otherwise only the complete before/after set of setup-added Mason packages and the setup-created JDT LS workspace are removed. Setup-created cache and temporary paths are removed from their recorded strict allowlist; diagnostic transcripts are retained intentionally.

An `UNINSTALLED` status is printed only after the component is confirmed absent, and its ownership state is cleared only after that verification. If removal or verification fails, ownership is retained so a later run can retry safely.

Run the repository regression test with:

```bat
python -m unittest discover -s tests
```

The suite covers expansion and runner behavior plus installer/uninstaller contracts for elevation, immutable retry state, worktree integrity, timeouts, process cleanup, silent package operations, user-owned configuration, Mason dependencies, and temporary artifacts. A clean-snapshot VM run is still required for a release-level E2E check of UAC and package installation.

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
|-- tests/                   Runner and setup regression tests
|-- workspace/               Only placeholders tracked; local contents ignored
|-- AGENTS.md                Guidance for coding agents
`-- README.md
```
