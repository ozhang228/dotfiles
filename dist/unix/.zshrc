# -- Environment -- 
export EDITOR='nvim'
export MANPAGER='nvim +Man!'
export PAGER='less'
export LESS='-R'

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

# emacs style shell bindings to not conflict when in nvim terminal 
bindkey -e

# zsh completions
autoload -Uz compinit
compinit -d ~/.zcompdump

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colors
zstyle ':completion:*' matcher-list \
  'm:{a-z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' # ignore case and separators

fastfetch --logo $HOME/dotfiles/imgs/conkeldurr_ascii.txt -c $HOME/dotfiles/core/fastfetch.jsonc # OS info

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
alias npmr="npm run"
alias p3="python3"

alias ga="git add"
alias gc="git commit"
alias gp="git push"

alias xdgo="xdg-open"

# Personal computer specific settings
source "$HOME/dotfiles/dist/unix/.zshrc_personal"

# Work computer specific settings
source "$HOME/dotfiles/dist/unix/.zshrc_work"


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/home/ozhang/.opam/opam-init/init.zsh' ]] || source '/home/ozhang/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration

[ -s "/home/ozhang/.scm_breeze/scm_breeze.sh" ] && source "/home/ozhang/.scm_breeze/scm_breeze.sh"

