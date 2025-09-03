#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Ubuntu bootstrap: symlink dotfiles + PPAs + apt + tools (nvim, lazygit, starship, uv, node, npm)
# Extensible, idempotent, noninteractive-friendly.
#
# Usage:
#   ./ubuntu-setup.sh [--no-symlinks] [--no-ppas] [--no-apt] [--no-nvim] [--no-lazygit]
#                     [--no-starship] [--no-uv] [--no-node] [--no-npm]
#                     [--only symlinks|ppas|apt|nvim|lazygit|starship|uv|node|npm]
#
# ──────────────────────────────────────────────────────────────────────────────

DO_SYMLINKS=1
DO_PPAS=1
DO_APT=1
DO_NVIM=1
DO_LAZYGIT=1
DO_STARSHIP=1
DO_UV=1
DO_NODE=1
DO_NPM=1
ONLY_SECTION=""

DOTFILES="$HOME/dotfiles"
export DEBIAN_FRONTEND=noninteractive

# ── helpers ───────────────────────────────────────────────────────────
log()  { printf "➤ %s\n" "$*"; }
ok()   { printf "✅ %s\n" "$*"; }
warn() { printf "⚠️  %s\n" "$*" >&2; }
err()  { printf "❌ %s\n" "$*" >&2; }

is_installed_dpkg() { dpkg -s "$1" &>/dev/null; }
is_installed_cmd()  { command -v "$1" &>/dev/null; }
is_installed_npm()  { npm list -g --depth=0 "$1" &>/dev/null; }

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

# ── args ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-symlinks) DO_SYMLINKS=0; shift;;
    --no-ppas)     DO_PPAS=0; shift;;
    --no-apt)      DO_APT=0; shift;;
    --no-nvim)     DO_NVIM=0; shift;;
    --no-lazygit)  DO_LAZYGIT=0; shift;;
    --no-starship) DO_STARSHIP=0; shift;;
    --no-uv)       DO_UV=0; shift;;
    --no-node)     DO_NODE=0; shift;;
    --no-npm)      DO_NPM=0; shift;;
    --only)        ONLY_SECTION="${2:-}"; shift 2;;
    -*)
      err "Unknown option: $1"; exit 1;;
    *)
      err "Unexpected argument: $1"; exit 1;;
  esac
done

if [[ -n "$ONLY_SECTION" ]]; then
  DO_SYMLINKS=0; DO_PPAS=0; DO_APT=0; DO_NVIM=0; DO_LAZYGIT=0; DO_STARSHIP=0; DO_UV=0; DO_NODE=0; DO_NPM=0
  case "$ONLY_SECTION" in
    symlinks) DO_SYMLINKS=1;;
    ppas)     DO_PPAS=1;;
    apt)      DO_APT=1;;
    nvim)     DO_NVIM=1;;
    lazygit)  DO_LAZYGIT=1;;
    starship) DO_STARSHIP=1;;
    uv)       DO_UV=1;;
    node)     DO_NODE=1;;
    npm)      DO_NPM=1;;
    *) err "--only expects one of: symlinks|ppas|apt|nvim|lazygit|starship|uv|node|npm"; exit 1;;
  esac
fi

# ── data ──────────────────────────────────────────────────────────────
declare -A SYMLINKS=(
  ["core/nvim"]="$HOME/.config/nvim"
  ["core/starship"]="$HOME/.config/starship"
  ["core/kitty"]="$HOME/.config/kitty"
  ["core/lazygit"]="$HOME/.config/lazygit"
  ["core/.gitconfig"]="$HOME/.gitconfig"
  ["core/lsd"]="$HOME/.config/lsd"
  ["dist/unix/.zshrc"]="$HOME/.zshrc"
  ["dist/unix/.fonts"]="$HOME/.fonts"
  ["dist/unix/rofi"]="$HOME/.config/rofi"
  ["dist/unix/.bashrc"]="$HOME/.bashrc"
)

APT_PPAS=(
  ppa:zhangsongcui3371/fastfetch
)

APT_APPS=(
  # tiling
  i3 rofi
  # CLI
  kitty zsh curl fd-find ripgrep jq gh lsd fastfetch xsel
  # languages/build
  build-essential python3-pip luarocks python3-venv
  # desktop utils
  pavucontrol alsa-utils blueman dunst feh
)

NPM_PKGS=( prettier )

# ── sections ─────────────────────────────────────────────────────────
section_symlinks() {
  (( DO_SYMLINKS )) || return
  log "Creating symlinks from $DOTFILES …"
  for rel in "${!SYMLINKS[@]}"; do
    local src="${DOTFILES}/${rel}"
    local dst="${SYMLINKS[$rel]}"
    if [[ ! -e "$src" ]]; then
      warn "Missing source, skipping: $src"
      continue
    fi
    create_symlink "$src" "$dst"
  done
  if [[ -L "$HOME/.fonts" || -d "$HOME/.fonts" ]]; then
    log "Rebuilding font cache …"
    fc-cache -fv || warn "fc-cache failed"
  fi
  ok "Dotfiles linked."
}

section_ppas() {
  (( DO_PPAS )) || return
  if ! is_installed_cmd add-apt-repository; then
    log "Installing software-properties-common …"
    sudo apt update -y
    sudo apt install -y software-properties-common
  fi
  for ppa in "${APT_PPAS[@]}"; do
    log "Adding PPA: $ppa"
    sudo add-apt-repository -y "$ppa"
  done
  ok "PPAs ensured."
}

section_apt() {
  (( DO_APT )) || return
  log "Updating apt package lists …"
  sudo apt update -y
  log "Installing apt packages …"
  sudo apt install -y "${APT_APPS[@]}"
  ok "apt packages ensured."

  # fd-find → fd shim
  mkdir -p "$HOME/.local/bin"
  if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ok "Linked fdfind → ~/.local/bin/fd"
  fi

  # fzf
  if ! is_installed_dpkg fzf && [[ ! -d "$HOME/.fzf" ]]; then
    log "Installing fzf from source (user) …"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    yes | "$HOME/.fzf/install" >/dev/null
    ok "fzf installed."
  else
    ok "fzf already installed."
  fi
}

section_nvim() {
  (( DO_NVIM )) || return
  if is_installed_cmd nvim; then
    ok "Neovim already installed: $(nvim --version | head -n1)"
    return
  fi
  log "Installing latest Neovim …"
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  sudo rm -rf /opt/nvim
  sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
  sudo mv /opt/nvim-linux-x86_64 /opt/nvim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -f nvim-linux-x86_64.tar.gz
  ok "Neovim installed: $(nvim --version | head -n1)"
}

section_lazygit() {
  (( DO_LAZYGIT )) || return
  if is_installed_cmd lazygit; then
    ok "lazygit already installed."
    return
  fi
  log "Installing latest lazygit …"
  LAZYGIT_VERSION="$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": *"v\K[^"]*')"
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install -D lazygit -t /usr/local/bin/
  rm -f lazygit lazygit.tar.gz
  ok "lazygit v${LAZYGIT_VERSION} installed."
}

section_starship() {
  (( DO_STARSHIP )) || return
  if is_installed_cmd starship; then
    ok "Starship already installed."
    return
  fi
  log "Installing Starship …"
  curl -fsSL https://starship.rs/install.sh | bash -s -- -y
  ok "Starship installed."
}

section_uv() {
  (( DO_UV )) || return
  if is_installed_cmd uv; then
    ok "uv already installed."
    return
  fi
  log "Installing uv …"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ok "uv installed."
}

section_node() {
  (( DO_NODE )) || return
  if is_installed_cmd node; then
    ok "Node.js already installed ($(node --version))."
    return
  fi
  log "Installing Node.js 20.x …"
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
  ok "Node.js installed ($(node --version))."
}

section_npm() {
  (( DO_NPM )) || return
  if ! is_installed_cmd npm; then
    warn "npm not found; skipping global npm packages."
    return
  fi
  log "Installing global npm packages …"
  for pkg in "${NPM_PKGS[@]}"; do
    if is_installed_npm "$pkg"; then
      ok "npm package already present: $pkg"
    else
      sudo npm install -g "$pkg"
      ok "npm -g installed: $pkg"
    fi
  done
}

# ── run ───────────────────────────────────────────────────────────────
log "Starting Ubuntu setup"
(( DO_SYMLINKS )) && log "Section: symlinks"
(( DO_PPAS     )) && log "Section: ppas"
(( DO_APT      )) && log "Section: apt"
(( DO_NVIM     )) && log "Section: nvim"
(( DO_LAZYGIT  )) && log "Section: lazygit"
(( DO_STARSHIP )) && log "Section: starship"
(( DO_UV       )) && log "Section: uv"
(( DO_NODE     )) && log "Section: node"
(( DO_NPM      )) && log "Section: npm"

section_symlinks
section_ppas
section_apt
section_nvim
section_lazygit
section_starship
section_uv
section_node
section_npm

ok "Ubuntu setup complete!"
