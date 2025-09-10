#!/usr/bin/env bash
set -euo pipefail

# macOS bootstrap: symlink dotfiles + brew formulas/casks + npm
# Compatible with macOS default Bash 3.x (no associative arrays)

DOTFILES="$HOME/dotfiles"

DO_SYMLINKS=1
DO_BREW=1
DO_NPM=1
ONLY_SECTION=""

# ── helpers ───────────────────────────────────────────
log()   { printf "➤ %s\n" "$*"; }
ok()    { printf "✅ %s\n" "$*"; }
warn()  { printf "⚠️  %s\n" "$*" >&2; }
err()   { printf "❌ %s\n" "$*" >&2; }
is_installed_brew() { brew list --formula "$1" &>/dev/null || brew list --cask "$1" &>/dev/null; }
is_installed_npm()  { npm list -g --depth=0 "$1" &>/dev/null; }

create_symlink() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    rm -rf "$dst"
    warn "Removed existing: $dst"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  ok "Symlink: $dst → $src"
}

# ── argument parsing ─────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-symlinks) DO_SYMLINKS=0; shift;;
    --no-brew)     DO_BREW=0; shift;;
    --no-npm)      DO_NPM=0; shift;;
    --only)
      ONLY_SECTION="${2:-}"; shift 2 ;;
    -*)
      err "Unknown option: $1"; exit 1 ;;
    *)
      err "Unexpected argument: $1"; exit 1 ;;
  esac
done

if [[ -n "$ONLY_SECTION" ]]; then
  case "$ONLY_SECTION" in
    symlinks) DO_SYMLINKS=1; DO_BREW=0; DO_NPM=0;;
    brew)     DO_SYMLINKS=0; DO_BREW=1; DO_NPM=0;;
    npm)      DO_SYMLINKS=0; DO_BREW=0; DO_NPM=1;;
    *) err "--only expects one of: symlinks|brew|npm"; exit 1;;
  esac
fi

# ── config: symlinks (list of "source_rel dest_abs") ──
SYMLINKS_LIST=(
  "core/nvim $HOME/.config/nvim"
  "core/starship $HOME/.config/starship"
  "core/lazygit $HOME/.config/lazygit"
  "core/kitty $HOME/.config/kitty"
  "core/.gitconfig $HOME/.gitconfig"
  "core/lsd $HOME/.config/lsd"
  "dist/unix/.zshrc $HOME/.zshrc"
  "dist/unix/.bashrc $HOME/.bashrc"
)

# ── config: brew formulas & casks ──
BREW_FORMULAS=(
  neovim
  lazygit
  starship
  kitty
  zsh
  lsd
  curl
  fd
  ripgrep
  jq
  fzf
  gh
  fastfetch
  python
  node
  lua
  luarocks
)

BREW_CASKS=(
  font-jetbrains-mono-nerd-font
)

# ── config: npm globals ──
NPM_PKGS=(
  prettier
)

# ── sections ────────────────────────────────────────
section_symlinks() {
  (( ! DO_SYMLINKS )) && return
  log "Creating symlinks"
  for entry in "${SYMLINKS_LIST[@]}"; do
    local rel dst src
    rel=$(printf "%s" "$entry" | cut -d' ' -f1)
    dst=$(printf "%s" "$entry" | cut -d' ' -f2-)
    src="${DOTFILES}/$rel"
    if [[ ! -e "$src" ]]; then
      warn "Missing source, skipping: $src"
      continue
    fi
    create_symlink "$src" "$dst"
  done
  ok "Dotfiles linked."
}

section_brew() {
  (( ! DO_BREW )) && return
  if ! command -v brew &>/dev/null; then
    log "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"
  fi
  log "Updating Homebrew..."
  brew update
  log "Installing brew formulas..."
  for pkg in "${BREW_FORMULAS[@]}"; do
    if is_installed_brew "$pkg"; then
      ok "Already installed: $pkg"
    else
      log "Installing formula: $pkg"
      brew install "$pkg"
    fi
  done
  log "Installing brew casks..."
  for pkg in "${BREW_CASKS[@]}"; do
    if is_installed_brew "$pkg"; then
      ok "Already installed: $pkg"
    else
      log "Installing cask: $pkg"
      brew install --cask "$pkg"
    fi
  done
  ok "Brew packages ensured."
}

section_npm() {
  (( ! DO_NPM )) && return
  if ! command -v npm &>/dev/null; then
    warn "npm not found; skipping global npm packages."
    return
  fi
  log "Installing global npm packages..."
  for pkg in "${NPM_PKGS[@]}"; do
    if is_installed_npm "$pkg"; then
      ok "Already installed: npm $pkg"
    else
      log "Installing (npm -g): $pkg"
      npm install -g "$pkg"
    fi
  done
  ok "Global npm packages ensured."
}

# ── main ─────────────────────────────────────────────
log "Starting macOS setup"
(( DO_SYMLINKS )) && log "Section: symlinks"
(( DO_BREW     )) && log "Section: brew"
(( DO_NPM      )) && log "Section: npm"

section_symlinks
section_brew
section_npm

ok "macOS setup complete."
