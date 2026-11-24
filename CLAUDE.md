# Dotfiles-specific conventions

- Format JSON files with `oxfmt --write <file>` before finishing an edit (config: `.oxfmtrc.json`). This matches the formatter nvim already applies on save (`src/terminal/nvim/lua/plugins/tools/formatters.lua`) for this repo, so hand-formatted JSON never drifts from what the editor produces. `oxfmt` lives at `~/.local/share/nvim/mason/bin/oxfmt`.
- `packages.json` and `symlinks.json` are read by `setup/main.py` (`--packages`, `--symlink`, `--check`). Run `cd setup && uv run pytest` after editing either, and `make doctor` to sanity-check the result.
