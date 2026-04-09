if status is-interactive

command -v lsd &>/dev/null && alias ls='lsd'

abbr -a py "python3"
abbr -a pm "sudo pacman"
abbr -a deltas "delta --side-by-side"

abbr -a dot "cd $HOME/dotfiles/;nvim"
abbr -a notes "cd $HOME/notes;nvim"
abbr -a ai "cd $HOME/ai;nvim"
abbr -a forge "cd $HOME/forge;nvim"

# check the template.cpp file against the output
abbr -a cfcheck 'f() { g++ "template.cpp" -g -o a.out && ./a.out < input.txt; }; f'

# project paths for work
set -gx dtc "$HOME/drw/desk-tools/typescript/packages/@desk-tools/common/"
set -gx dtts "$HOME/drw/desk-tools/typescript/"
set -gx dtpy "$HOME/drw/desk-tools/python"
set -gx k8 "$HOME/drw/k8s"
set -gx alp "$HOME/drw/alp-config"
set -gx appl "$HOME/drw/app-launcher"

# swap escape on ubuntu and manjaro
set -gx XKB_DEFAULT_OPTIONS caps:swapescape
end

