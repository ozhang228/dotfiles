if status is-interactive

command -v lsd &>/dev/null && alias ls='lsd'

abbr -a py "python3"
abbr -a pm "sudo pacman"
abbr -a aic "~/ai/copy.fish"

abbr -a dot "cd ~/dotfiles/;nvim"
abbr -a notes "cd ~/notes;nvim"

# check the template.cpp file against the output
abbr -a cfcheck 'f() { g++ "template.cpp" -g -o a.out && ./a.out < input.txt; }; f'

# project paths for work
set -gx dtc "~/drw/desk-tools/typescript/packages/@desk-tools/common/"
set -gx dtts "~/drw/desk-tools/typescript/"
set -gx dtpy "~/drw/desk-tools/python"
set -gx k8 "~/drw/k8s"
set -gx alp "~/drw/alp-config"
set -gx appl "~/drw/app-launcher"

end
