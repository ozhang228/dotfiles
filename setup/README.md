# Dotfile Setup Script

- `../packages.json` and `../symlinks.json` (repo root) are the two sources of truth. Install scripts live under `ubuntu/`, `manjaro/`, and `scripts/` (shared across distros).
- If `~/anvil/packages.json` or `~/anvil/symlinks.json` exist, they're merged in additively on top of this repo's own manifests.
- Run from the repo root: `make ubuntu` / `make manjaro` / `make mac` installs packages for that distro; `make symlink` links everything.
