# Set up fzf key bindings and fuzzy completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
. "$HOME/.local/bin/env"

# Setup Starship Prompt
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Setup Zoxide
eval "$(zoxide init zsh)"

# see hidden files
setopt globdots

# go to root on startup for wsl (might remove if its annoying in the future)
cd $HOME

# OS info
fastfetch --logo ~/dotfiles/imgs/pangoro_ascii.txt -c paleofetch
