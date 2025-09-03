# -- Environment -- 
export EDITOR='nvim'
export MANPAGER='nvim +Man!'
export PAGER='less'
export LESS='-R'
export CONDA_CHANGEPS1=false

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt HIST_IGNORE_SPACE

setopt INTERACTIVE_COMMENTS
setopt PIPE_FAIL

setopt PROMPT_SUBST # allow var substitution in prompt
setopt globdots # hidden files

path=("$HOME/.local/bin" $path) # base path 

# history file setup
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# emacs style shell bindings to not conflict with vim
bindkey -e

# zsh completions
autoload -Uz compinit
compinit -d ~/.zcompdump

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colors
zstyle ':completion:*' matcher-list \
  'm:{a-z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' # ignore case and separators

# fzf key bindings and fuzzy completion
if [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  [[ -r /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
elif command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

fastfetch --logo $HOME/dotfiles/imgs/pangoro_ascii.txt -c $HOME/dotfiles/core/fastfetch.jsonc # OS info

# Starship Prompt
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Aliases
if command -v lsd >/dev/null 2>&1; then
  alias ls='lsd'
fi
alias pm="sudo pacman"
alias p3="python3"
alias npmr="npm run"

alias dot="cd ~/dotfiles;nvim ."
alias notes="cd ~/notes;nvim ."

# Work Aliases

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
