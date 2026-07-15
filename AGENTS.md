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
- Keep the inlined Python helper state closure-isolated from solution globals, and retain the regression test that shadows debug flags, modules, builtins, helper internals, and public helper names.

## Install And Uninstall Safety

- Capture the invoking user's SID, session, profile, LocalAppData, and AppData before elevation. Keep setup state under the protected machine key `HKLM\Software\my-cp-setup\Users\<SID>`. Use the elevated token only for machine components and protected-state snapshot/verification/commit; execute actual User-registry, profile-data, Neovim, and repository mutations with the invoking user's medium token, even when UAC credentials belong to another administrator. Validate the worker SID, session, non-elevated token, integrity level, executable paths, and process-tree lifetime. `--check` stays read-only and unelevated.
- Never elevate an executable helper generated in a user-writable temporary directory. Launch the one UAC child with only fixed validated arguments and the `CreateNew` batch copy inside the protected runtime; resolve Windows system tools from System32, and never execute a target-user-writable tool from an elevated process. WinGet-managed packages and their ownership checks use machine scope.
- Hold the original batch source open without write/delete sharing across elevation. Resolve its final path and read its hash and bytes through that same handle, create the elevated copy with `CreateNew` inside the validated protected runtime, and execute only that copy while the source lease remains open. Do not reopen the original pathname or require non-portable locks on profile ancestor directories.
- Read target-user `REG_EXPAND_SZ` values without expansion, preserve their registry kind in snapshots, and expand them only with the target profile environment active. Privileged recursive cleanup must use the protected canonical roots captured during installation and must reject reparse-point traversal.
- Capture pre-existing state before changing user configuration or adding packages, then record only components the setup actually created. Uninstall only exact setup-owned components and restore a value only when it still equals the setup-written value.
- Keep initial snapshots immutable across retries, including a snapshot-only interrupted install. Treat partially written ownership metadata as an error, but allow safe removal of a complete snapshot that has no corresponding mutation marker.
- Cleanup steps that intentionally tolerate already-missing state must return explicit success; genuine failures must retain a component-specific message or log instead of falling through to only the global failure status.
- Accept Node.js only when `process.release.lts` identifies an LTS build, and validate npm separately.
- Every long-running external package operation must use a finite process-tree watchdog, terminate descendants on timeout, and preserve its component log without changing the normal spinner/status flow.
- Elevated children must exit without `pause` or `ReadKey`. The original process owns the concise completion summary, complete transcript destination, and exact child exit code. Cancellation and timeout must be nonzero; timeout uses exit code 124.
- Print terminal uninstall success and clear setup ownership only after the package or files are independently confirmed absent; retain ownership state after any removal or verification failure.
- Add to User PATH only `scripts` and directories containing executables the installer has resolved and validated. Remove obsolete setup-owned alternatives during migration without removing pre-existing or user-owned entries.
- Never remove repository-owned Neovim configuration. Remove generated `nvim-data` in full only when it did not predate setup; otherwise remove only recorded setup-owned Mason packages and the exact setup-created JDT LS workspace.
- Keep the pre-bootstrap `nvim-data`, Mason package, and JDT LS workspace snapshots immutable across installer retries. Derive setup-owned Mason packages from the complete post-bootstrap inventory minus the complete original inventory, including packages installed as indirect dependencies.
- Keep installer-owned Mason bootstrap separate from LazyVim's automatic `ensure_installed` run. Completion must use Mason success/failure callbacks or events rather than package-directory existence, report per-tool progress, fail on refresh/install errors, and retain an external process-tree watchdog.
- Neovim bootstrap must treat the repository worktree and `nvim/lazy-lock.json` as read-only: keep the lockfile handle open without write sharing and hash the complete worktree before and after each phase. Perform setup writes only in the protected runtime, never by reopening a mutable repository path from an elevated process.
- Record temporary/cache ownership as strict canonical before/after path sets, reject reparse traversal, and remove only setup-created entries. Retain full `cp_setup_*.log` transcripts as an explicit diagnostic policy.
- Let LazyVim own capability-aware LSP navigation/action mappings and format-on-save. Keep the project's single `<leader>cf` manual-format mapping, but do not add unconditional duplicates, a second `BufWritePre` formatter, or a second autopairs implementation alongside `mini.pairs`.

## Editing And Validation

- Respect `.gitattributes`: batch/CMD files use CRLF and source, Lua, Python, and Markdown files use LF.
- Run focused checks first, then `scripts\install.bat --check` when practical. Confirm ignored workspace files and temporary artifacts remain untracked.
- Do not commit or push unless the user explicitly asks.
