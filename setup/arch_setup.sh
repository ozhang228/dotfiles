#!/usr/bin/env bash
set -euo pipefail

# -- Create symlinks
dotfiles="$HOME/dotfiles"

declare -A symlinks=(
  ["core/nvim"]="$HOME/.config/nvim"
  ["core/starship"]="$HOME/.config/starship"
  ["core/lazygit"]="$HOME/.config/lazygit"
  ["dist/unix/.zshrc"]="$HOME/.zshrc"
  ["dist/unix/.bashrc"]="$HOME/.bashrc"
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
  # CLI
  curl
  fd
  ripgrep
  zoxide
  jq
  fzf
  gh
  fastfetch
  # languages
  luarocks
  build-essential
  python3-pip
  nodejs
  npm
  # this is necessary because of a bug in mason 
  python3-venv
)

# update package list
sudo pacman -Sy

echo "📦 Installing packages..."
for pkg in "${pacman_apps[@]}"; do
  if dpkg -s "$pkg" &>/dev/null; then
    echo "✅ $pkg already installed"
  else
    echo "⏬ Installing $pkg..."
    sudo pacman -S "$pkg"
  fi
done

## -- Install uv package manager for Python
if command -v uv &>/dev/null; then
  echo "✅ UV already installed. Skipping…"
else
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

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
