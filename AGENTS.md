# Agent Guidelines

## Project Invariants

- This is a Windows 11 competitive-programming setup for C++, Java, and Python.
- Keep `scripts/install.bat` and `scripts/uninstall.bat` as the only tracked install/uninstall scripts. Do not add installer helpers or alternate entry points.
- Preserve the installer/uninstaller prompts, options, status labels, and spinner flow unless the user approves a UX change. External package operations must remain silent and non-interactive.
- Keep exactly one blank line between major installer/uninstaller sections and interactive prompt groups; status and prompt lines belonging to the same group stay adjacent.
- Initial component detection may report `SEARCHING` followed by `FOUND`; post-install verification must stay silent and report one `INSTALLED` only after package, executable, and integrity checks succeed. The `ac-library` probe uses `SEARCHING`, then `UP TO DATE` for the pinned tree or `INSTALLING`/`UPDATING` followed by a silently verified terminal status.
- Keep the tracked templates in `template/`. Under `workspace/`, track only the three language directories through their `.gitkeep` files; never add local solutions or test data to Git.
- Do not modify the vendored AtCoder Library in `libraries/ac-library`.
- Source-archive `ac-library` repairs may adopt an exact pinned tree for migration, but must verify a same-volume staging tree before replacement, replace only an empty target or a stale tree matching the recorded setup-managed hash, and retain a rollback copy until the final pinned-tree check passes.
- Keep `my_libraries` focused on lightweight contest conveniences and align equivalent debug/timer behavior across the three languages where practical.
- Keep `nvim/lua/plugins/example.lua`; it is an intentionally disabled LazyVim-generated example.

## Runtime And Submission Safety

- Keep runner-built C++ executables and Java class output in temporary directories, run Python with bytecode generation disabled, and clean temporary expansion files on both success and failure.
- Submission writes must remain atomic. Failed expansion must not replace an existing `submit.*`, and verification/setup checks must not change the clipboard or repository workspace.
- Generated submissions must disable local diagnostics. Java sources must use qualified `Cp.member(...)` access; keep the explicit rejection of static imports from `my_libraries.Cp`.
- Keep the inlined Python helper state closure-isolated from solution globals, including when solution code shadows debug flags, modules, builtins, helper internals, or public helper names.
- Let LazyVim own capability-aware LSP navigation/action mappings and format-on-save. Keep the project's single `<leader>cf` manual-format mapping, but do not add unconditional duplicates, a second `BufWritePre` formatter, or a second autopairs implementation alongside `mini.pairs`.

## Install And Uninstall Safety

- Normal installation/uninstallation may request one UAC elevation when needed and must not reject the invoking account before Windows processes that request; `--check` must remain read-only and usable without elevation.
- Capture pre-existing state before changing user configuration or adding packages, then record only components the setup actually created. Uninstall only exact setup-owned components and restore a value only when it still equals the setup-written value.
- Cleanup steps that intentionally tolerate already-missing state must return explicit success; genuine failures must retain a component-specific message or log instead of falling through to only the global failure status.
- Add to User PATH only `scripts` and directories containing executables the installer has resolved and validated. Remove obsolete setup-owned alternatives during migration without removing pre-existing or user-owned entries.
- Never remove repository-owned Neovim configuration. Remove generated `nvim-data` in full only when it did not predate setup; otherwise remove only recorded setup-owned Mason packages and the exact setup-created JDT LS workspace.
- Keep installer-owned Mason bootstrap separate from LazyVim's automatic `ensure_installed` run. Completion must use Mason success/failure callbacks or events rather than package-directory existence, report per-tool progress, fail on refresh/install errors, and retain an external process-tree watchdog.

## Editing And Validation

- Respect `.gitattributes`: batch/CMD files use CRLF and source, Lua, Python, and Markdown files use LF.
- Run focused checks first, then `scripts\install.bat --check` when practical. Confirm ignored workspace files and temporary artifacts remain untracked.
- Do not commit or push unless the user explicitly asks.
