#!/usr/bin/env bash
set -euo pipefail

# -- Create symlinks
dotfiles="$HOME/dotfiles"

declare -A symlinks=(
  ["core/nvim"]="$HOME/.config/nvim"
  ["core/starship"]="$HOME/.config/starship"
  ["core/lazygit"]="$HOME/.config/lazygit"
  ["core/kitty"]="$HOME/.config/kitty"
  ["dist/unix/rofi"]="$HOME/.config/rofi"
  ["dist/unix/hyprpanel"]="$HOME/.config/hyprpanel"
  ["dist/unix/.zshrc"]="$HOME/.zshrc"
  ["dist/unix/.bashrc"]="$HOME/.bashrc"
  ["dist/unix/hypr"]="$HOME/.config/hypr"
)

echo "🔗 Creating symlinks from $dotfiles..."

for src in "${!symlinks[@]}"; do
  src_path="$dotfiles/$src"
  dst_path="${symlinks[$src]}"

  # Remove any existing file/dir/link
  if [ -e "$dst_path" ] || [ -L "$dst_path" ]; then
    rm -rf "$dst_path"
    echo "❌ Removed existing: $dst_path"
  fi

  mkdir -p "$(dirname "$dst_path")"
  ln -s "$src_path" "$dst_path"
  echo "✅ Symlink: $dst_path → $src_path"
done


# -- Install CLI dependencies via pacman
pacman_apps=(
  # Core
  neovim
  lazygit
  starship
  kitty
  hyprland
  # CLI
  zsh
  curl
  fd
  ripgrep
  zoxide
  jq
  fzf
  github-cli
  fastfetch
  wl-clipboard
  ttf-jetbrains-mono-nerd
  rofi-wayland
  hyprcursor
  hyprpaper
  xdg-desktop-portal-hyprland # screen sharing
  xdg-desktop-portal-gtk
  # languages
  lua51 # 5.1 for rest.nvim but upgrade as needed
  luarocks
  base-devel
  python
  python-pip
  uv
  nodejs
  npm
  # GUIs
  vivaldi
)

# update package list
sudo pacman -Sy

echo "📦 Installing packages..."
for pkg in "${pacman_apps[@]}"; do
  if pacman -Qk "$pkg" &>/dev/null; then
    echo "✅ $pkg already installed"
  else
    echo "⏬ Installing $pkg..."
    sudo pacman -S "$pkg"
  fi
done

# -- Setup AUR with yay
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git ~/yay
  cd ~/yay
  makepkg -si
  cd ~
  rm -rf ~/yay
fi

# -- Install CLI dependencies via yay
aur_apps=(
  ags-hyprpanel-git
  bibata-cursor-theme
  hyprshot
)

# update package list
yay -Sy

echo "📦 Installing AUR packages..."
for pkg in "${aur_apps[@]}"; do
  if yay -Qk "$pkg" &>/dev/null; then
    echo "✅ $pkg already installed"
  else
    echo "⏬ Installing $pkg..."
    yay -S "$pkg"
  fi
done

# -- Install global npm packages
npm_pkgs=(
  prettier
)

echo "📦 Installing global npm packages..."
for pkg in "${npm_pkgs[@]}"; do
  if npm list -g --depth=0 "$pkg" &>/dev/null; then
    echo "✅ npm package $pkg already installed"
  else
    echo "⏬ Installing npm package $pkg..."
    sudo npm install -g "$pkg"
  fi
done

# -- Git 
git config --global user.name "Oscar Zhang"
git config --global user.email "oscarzhang228@gmail.com"

echo "🎉 Arch terminal setup complete!"
