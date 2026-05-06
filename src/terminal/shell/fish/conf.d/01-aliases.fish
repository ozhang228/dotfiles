if status is-interactive

command -v lsd &>/dev/null && alias ls='lsd'

abbr -a py "python3"
abbr -a pm "sudo pacman"
abbr -a deltas "delta --side-by-side"

abbr -a dot "cd $HOME/dotfiles/;nvim"
abbr -a forge "cd $HOME/forge;nvim"

# check the template.cpp file against the output
abbr -a cfcheck 'f() { g++ "template.cpp" -g -o a.out && ./a.out < input.txt; }; f'

# swap escape on ubuntu and manjaro
set -gx XKB_DEFAULT_OPTIONS caps:swapescape
end

