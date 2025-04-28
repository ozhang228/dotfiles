# fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Starship Prompt
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Zoxide
eval "$(zoxide init zsh)"

# see hidden files
setopt globdots

# Go to ~ on startup and clear the screen
clear
cd $HOME

# OS Info Startup screen
fastfetch --logo ~/dotfiles/imgs/pangoro_ascii.txt -c paleofetch
