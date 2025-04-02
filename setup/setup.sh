#!/bin/bash

# -- Setup Symlinks
dotfiles="$HOME/dotfiles"

declare -A symlinks=(
  ["core/nvim"]="$HOME/.config/nvim"
  ["core/wezterm"]="$HOME/.config/wezterm"
  ["core/starship"]="$HOME/.config/starship"
  ["core/lazygit"]="$HOME/.config/lazygit"
)

echo "🔗 Creating symlinks from $dotfiles..."

for src in "${!symlinks[@]}"; do
  sourcePath="$dotfiles/$src"
  destinationPath="${symlinks[$src]}"

    # Remove existing destination if it exists
    if [ -e "$destinationPath" ] || [ -L "$destinationPath" ]; then
      rm -rf "$destinationPath"
      echo "❌ Removed existing: $destinationPath"
    fi

    # Ensure parent directory exists
    mkdir -p "$(dirname "$destinationPath")"

    # Create symlink
    ln -s "$sourcePath" "$destinationPath"
    echo "✅ Symlink created: $destinationPath -> $sourcePath"
  done

# -- Install Dependencies
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew installed. Skipping..." 
fi

brew_apps=(
    neovim
    fd
    ripgrep
    lazygit
    wezterm
    starship
    zoxide
    jetbrainsmono-nerd-font
    fzf
)

echo "🔧 Installing packages via brew..."

for app in "${brew_apps[@]}"; do
    if brew list --formula --cask "$app" &>/dev/null; then
        echo "✅ $app is already installed. Skipping..."
    else
        echo "📦 Installing $app..."
        brew install "$app" || brew install --cask "$app"
    fi
done


