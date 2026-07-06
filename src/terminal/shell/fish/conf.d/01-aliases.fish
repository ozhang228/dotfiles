if status is-interactive

command -v lsd &>/dev/null && alias ls='lsd'

abbr -a py "python3"
abbr -a pm "sudo pacman"
abbr -a marimo "uv run marimo"

abbr -a dot "cd $HOME/dotfiles/;nvim"
abbr -a forge "cd $HOME/forge;nvim"

# swap escape on ubuntu and manjaro
set -gx XKB_DEFAULT_OPTIONS caps:swapescape
end

