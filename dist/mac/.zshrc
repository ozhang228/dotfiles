export OS="MAC"
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Setup Starship Prompt
eval "$(starship init zsh)"

# Setup Zoxide
eval "$(zoxide init zsh)"
