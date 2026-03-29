command -v lsd &>/dev/null && alias ls='lsd'

abbr -a py "python3"
abbr -a pm "sudo pacman"
abbr -a aic "~/ai/copy.fish"

abbr -a dot "cd ~/dotfiles/;nvim"
abbr -a notes "cd ~/notes;nvim"

# check the template.cpp file against the output
abbr -a cfcheck 'f() { g++ "template.cpp" -g -o a.out && ./a.out < input.txt; }; f'

# project paths for work
abbr -a dtc "~/drw/desk-tools/typescript/packages/@desk-tools/common/"
abbr -a dtts "~/drw/desk-tools/typescript/"
abbr -a dtpy "~/drw/desk-tools/python"
abbr -a k8s "~/drw/k8s"
