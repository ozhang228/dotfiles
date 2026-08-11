if status is-interactive

set -l logo (random choice $HOME/dotfiles/imgs/fastfetch/*.txt)
fastfetch --logo $logo -c $HOME/dotfiles/src/terminal/fastfetch/fastfetch.jsonc

end
