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


# -- Install CLI dependencies via apt
echo "🔄 Updating package lists..."
sudo apt-get update -qq

apt_apps=(
  curl
  fd-find
  ripgrep
  zoxide
  fzf
  jq
  luarocks
  gh
  # gcc / g++
  build-essential
)

echo "📦 Installing apt packages..."
for pkg in "${apt_apps[@]}"; do
  if dpkg -s "$pkg" &>/dev/null; then
    echo "✅ $pkg already installed"
  else
    echo "⏬ Installing $pkg..."
    sudo apt-get install -y "$pkg"
  fi
done

# have to do something special for fd to alias it
ln -s $(which fdfind) ~/.local/bin/fd

# -- Install Fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# -- Install Neovim
if ! command -v nvim &>/dev/null; then
  echo "🔄 Neovim not found. Installing latest from GitHub…"
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  sudo rm -rf /opt/nvim
  sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
  sudo mv /opt/nvim-linux-x86_64 /opt/nvim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm nvim-linux-x86_64.tar.gz
  echo "✅ Installed Neovim: $(nvim --version | head -n1)"
else
 echo "✅ Neovim already installed. Skipping…"
fi

# -- Install Lazygit
if command -v lazygit &>/dev/null; then
  echo "✅ lazygit already installed. Skipping…"
else
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit -D -t /usr/local/bin/
  rm lazygit lazygit.tar.gz
  echo "✅ lazygit v${LAZYGIT_VERSION} installed"
fi

# -- Install Starship
if ! command -v starship &>/dev/null; then
  echo "⏬ Installing Starship prompt..."
  curl -sS https://starship.rs/install.sh | sh
else
  echo "✅ Starship already installed"
fi
# -- Install Node.js & npm (via NodeSource)
if ! command -v node &>/dev/null; then
  echo "⏬ Setting up Node.js 20.x repository..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  echo "⏬ Installing nodejs..."
  sudo apt-get install -y nodejs
else
  echo "✅ Node.js already installed ($(node --version))"
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

echo "🎉 Ubuntu terminal setup complete!"
