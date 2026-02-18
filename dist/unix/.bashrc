# pnpm
export PNPM_HOME="/home/ozhang/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
. "$HOME/.cargo/env"

# >>> conda initialize >>> added by desk-tools bento
# . /home/ozhang/miniconda3/etc/profile.d/conda.sh  # commented out by conda initialize  # commented out by conda initialize

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -s "/home/ozhang/.scm_breeze/scm_breeze.sh" ] && source "/home/ozhang/.scm_breeze/scm_breeze.sh"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"
eval "$(pyenv virtualenv-init -)"


# Execute zsh by default
if test -t 1; then 
exec zsh
fi
