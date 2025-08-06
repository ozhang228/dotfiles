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
alias npmr="npm run"
alias pdf="zathura"

alias dot="cd ~/dotfiles"
alias notes="cd ~/notes"
alias nv.="nvim ."

### Work Aliases ###

alias dsbe="conda activate desk-tools;cd ~/projects/desk-tools/python/fio/desk_tools/apps/data_studio/;nvim ."
alias dsfe="cd ~/projects/app-launcher/distinct-builds/data-studio/; nvim ."
alias ca="conda activate"

####################

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/ozhang/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/ozhang/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/ozhang/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/ozhang/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<



