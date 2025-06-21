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

# Clear screen and show os info 
clear
fastfetch --logo $HOME/dotfiles/imgs/pangoro_ascii.txt -c $HOME/dotfiles/core/fastfetch.jsonc

export MANPAGER='nvim +Man!'

alias pm="sudo pacman"
alias p3="python3"
alias dot="cd ~/dotfiles; nvim ."

# Conda
export PATH="$HOME/miniconda3/bin:$PATH"
