#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Manjaro bootstrap: symlink dotfiles + packages (pacman, AUR, npm)
# Extensible, idempotent, safe backups, dry-run capable.
#
# Usage:
#   ./manjaro-setup.sh [--no-symlinks] [--no-pacman] [--no-aur] [--no-npm]
#                      [--only symlinks|pacman|aur|npm]
#
# ──────────────────────────────────────────────────────────────────────────────

DOTFILES="$HOME/dotfiles"
DO_SYMLINKS=1
DO_PACMAN=1
DO_AUR=1
DO_NPM=1
ONLY_SECTION=""

# ── helpers ───────────────────────────────────────────────────────────
log()  { printf "➤ %s\n" "$*"; }
ok()   { printf "✅ %s\n" "$*"; }
warn() { printf "⚠️  %s\n" "$*" >&2; }
err()  { printf "❌ %s\n" "$*" >&2; }
timestamp() { date +"%Y%m%d-%H%M%S"; }
is_installed_pacman() { pacman -Qi "$1" &>/dev/null; }   
is_installed_yay()    { yay -Qi "$1" &>/dev/null; }
is_installed_npm()    { npm list -g --depth=0 "$1" &>/dev/null; }

create_symlink() {
  local src="$1" dst="$2"

  # Remove any existing file/dir/link
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    rm -rf "$dst"
    warn "Removed existing: $dst"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  ok "✅ Symlink: $dst → $src"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-symlinks) DO_SYMLINKS=0; shift;;
    --no-pacman)   DO_PACMAN=0; shift;;
    --no-aur)      DO_AUR=0; shift;;
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
    symlinks) DO_SYMLINKS=1; DO_PACMAN=0; DO_AUR=0; DO_NPM=0;;
    pacman)   DO_SYMLINKS=0; DO_PACMAN=1; DO_AUR=0; DO_NPM=0;;
    aur)      DO_SYMLINKS=0; DO_PACMAN=0; DO_AUR=1; DO_NPM=0;;
    npm)      DO_SYMLINKS=0; DO_PACMAN=0; DO_AUR=0; DO_NPM=1;;
    *) err "--only expects one of: symlinks|pacman|aur|npm"; exit 1;;
  esac
fi

declare -A SYMLINKS=(
  ["core/nvim"]="$HOME/.config/nvim"
  ["core/starship"]="$HOME/.config/starship"
  ["core/lazygit"]="$HOME/.config/lazygit"
  ["core/kitty"]="$HOME/.config/kitty"
  ["core/.gitconfig"]="$HOME/.gitconfig"
  ["core/Dygma"]="$HOME/Dygma"
  ["core/lsd"]="$HOME/.config/lsd"
  ["dist/unix/rofi"]="$HOME/.config/rofi"
  ["dist/unix/hyprpanel"]="$HOME/.config/hyprpanel"
  ["dist/unix/.zshrc"]="$HOME/.zshrc"
  ["dist/unix/.bashrc"]="$HOME/.bashrc"
  ["dist/unix/hypr"]="$HOME/.config/hypr"
)

PACMAN_APPS=(
  # Core
  neovim lazygit starship kitty hyprland
  # CLI
  zsh lsd curl fd ripgrep jq fzf github-cli fastfetch wl-clipboard
  ttf-jetbrains-mono-nerd rofi-wayland hyprcursor hyprpaper
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  hypridle hyprlock hyprpolkitagent
  # languages & build
  lua51 luarocks base-devel python python-pip uv nodejs npm
  # GUI
  vivaldi
)

AUR_APPS=(
  ags-hyprpanel-git
  bibata-cursor-theme
  hyprshot
)

NPM_PKGS=(
  prettier
)

section_symlinks() {
  if (( ! DO_SYMLINKS )); then return; fi
  log "Creating symlinks"

  for rel in "${!SYMLINKS[@]}"; do
    local src="${DOTFILES}/$rel"
    local dst="${SYMLINKS[$rel]}"

    if [[ ! -e "$src" ]]; then
      warn "Missing source, skipping: $src"
      continue
    fi

    create_symlink "$src" "$dst"
  done
  ok "Dotfiles linked."
}

section_pacman() {
  if (( ! DO_PACMAN )); then return; fi
  log "Syncing pacman database …"

  sudo pacman -Sy
  log "Installing pacman packages …"
  for pkg in "${PACMAN_APPS[@]}"; do
    if is_installed_pacman "$pkg"; then
      ok "Already installed: $pkg"
    else
      log "Installing: $pkg"
      sudo pacman -S --needed -- $pkg
    fi
  done
  ok "Pacman packages ensured."
}

ensure_yay() {
  if command -v yay &>/dev/null; then
    ok "yay present."
    return
  fi
  log "Bootstrapping yay (AUR helper) …"

  sudo pacman -S --needed -- base-devel git

  rm -rf \"$HOME/yay\"
  git clone https://aur.archlinux.org/yay.git \"$HOME/yay\"
  (
    cd "$HOME/yay"
    makepkg -si
  )
  rm -rf "$HOME/yay"
  ok "yay installed."
}

section_aur() {
  if (( ! DO_AUR )); then return; fi
  ensure_yay
  log "Syncing AUR database …"
  yay -Sy

  log "Installing AUR packages …"
  for pkg in "${AUR_APPS[@]}"; do
    if is_installed_yay "$pkg"; then
      ok "Already installed: $pkg"
    else
      log "Installing (AUR): $pkg"
      yay -S $yesflag -- "$pkg"
    fi
  done
  ok "AUR packages ensured."
}

section_npm() {
  if (( ! DO_NPM )); then return; fi
  if ! command -v npm &>/dev/null; then
    warn "npm not found; skipping global npm packages."
    return
  fi

  log "Installing global npm packages …"
  for pkg in "${NPM_PKGS[@]}"; do
    if is_installed_npm "$pkg"; then
      ok "Already installed: npm $pkg"
    else
      log "Installing (npm -g): $pkg"
      sudo npm install -g "$pkg"
    fi
  done
  ok "Global npm packages ensured."
}

# ── ───────────────────────────────────────────────────────────────
log "Starting Manjaro setup"
(( DO_SYMLINKS )) && log "Section: symlinks"
(( DO_PACMAN  )) && log "Section: pacman"
(( DO_AUR     )) && log "Section: aur"
(( DO_NPM     )) && log "Section: npm"

section_symlinks
section_pacman
section_aur
section_npm

ok "Manjaro setup complete."
