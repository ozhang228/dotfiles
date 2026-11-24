fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.opencode/bin"
fish_add_path "$HOME/go/bin"

# Color tools treat the presence of NO_COLOR as disabled colors, regardless of its value.
set -e NO_COLOR

set -gx EDITOR "nvim"

# C/C++ compiler and vcpkg
set -gx CC "clang"
set -gx CXX "clang++"
set -gx VCPKG_ROOT "$HOME/.local/vcpkg"

# colors in conda
set -gx CONDA_CHANGEPS1 true
# disable greeting
set fish_greeting

set -gx JQ_COLORS "0;37:0;31:0;32:0;33:0;33:0;35:0;36:0;34"

# Claude Code clamps to 256 colors inside tmux unless set;
set -gx CLAUDE_CODE_TMUX_TRUECOLOR 1

# Catppuccin Macchiato — keeps fzf's own picker readable against the dark terminal bg
set -e FZF_DEFAULT_OPTS
set -gx FZF_DEFAULT_OPTS_FILE "$HOME/dotfiles/src/terminal/fzf/opts"

# Catppuccin via the terminal palette for newt TUIs such as nmtui
set -gx NEWT_COLORS '
root=white,black
roottext=white,black
window=white,black
border=blue,black
shadow=black,black
title=brightblue,black
label=white,black
textbox=white,black
acttextbox=black,blue
entry=white,black
disentry=brightblack,black
checkbox=white,black
actcheckbox=black,blue
listbox=white,black
actlistbox=black,blue
sellistbox=black,brightblue
actsellistbox=black,brightmagenta
button=black,blue
actbutton=black,brightmagenta
compactbutton=white,black
helpline=black,blue
emptyscale=,black
fullscale=,blue
'
