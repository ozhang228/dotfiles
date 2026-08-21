fish_add_path "$HOME/.local/bin"
fish_add_path /home/ozhang/.opencode/bin

set -gx EDITOR "nvim"

# C/C++ compiler and vcpkg
set -gx CC "clang"
set -gx CXX "clang++"
set -gx VCPKG_ROOT "$HOME/.local/vcpkg"

# colors in conda
set -gx CONDA_CHANGEPS1 true
# disable greeting
set fish_greeting

set -gx JQ_COLORS "1;38;2;102;112;123:0;38;2;160;17;31:0;38;2;5;93;32:0;38;2;116;69;0:0;38;2;112;44;0:0;38;2;81;37;152:0;38;2;27;124;131"

# GitHub Light High Contrast — keeps fzf's own picker readable against the light terminal bg
set -gx FZF_DEFAULT_OPTS '--cycle --layout=reverse --border --height=90% --preview-window=wrap,border-left,noinfo --marker="*" --color=fg:#010409,bg:#ffffff,hl:#512598,fg+:#010409,bg+:#e7ecf0,hl+:#0349b4,info:#1b7c83,prompt:#0349b4,pointer:#d1242f,marker:#055d20,spinner:#744500,header:#4b535d,border:#66707b,preview-border:#66707b,label:#010409'

