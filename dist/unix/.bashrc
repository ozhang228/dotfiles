# Execute zsh by default
if test -t 1; then 
exec zsh
fi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
