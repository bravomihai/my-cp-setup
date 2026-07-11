# Agent Guidelines

## Project Boundaries

- This is a Windows competitive-programming setup. Keep `scripts/install.bat` as the only installer; do not add alternative install scripts.
- Preserve the existing installer and uninstaller interface, options, status labels, and spinner behavior unless a change explicitly requires otherwise.
- Do not modify the vendored AtCoder Library in `libraries/cpp/ac-library`.
- Keep `my_libraries` focused on lightweight contest conveniences. Do not turn the Java or Python helpers into large algorithms or data-structures libraries.
- Keep the C++, Java, and Python templates and small helper conventions logically aligned where appropriate.

## Uninstall Safety

- Never remove repository-owned Neovim configuration. Only remove generated LazyVim data when the uninstaller flow explicitly covers it.
- Do not broaden uninstall deletion scope beyond setup-managed paths, environment variables, registry values, and user-confirmed components.

## Editing and Validation

- Respect `.gitattributes`; do not introduce mixed line endings.
- For installer, uninstaller, templates, or helper changes, run the narrowest relevant checks first. Use `scripts\install.bat --check` for an end-to-end setup verification when practical.
- Do not commit or push unless the user explicitly asks.
