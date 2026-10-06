fish_add_path "$HOME/.local/bin"
fish_add_path /home/ozhang/.opencode/bin
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

# Gruvbox Light Hard — keeps fzf's own picker readable against the light terminal bg
set -gx FZF_DEFAULT_OPTS '--cycle --layout=reverse --border --height=90% --info=hidden --preview-window=wrap,border-left,noinfo --marker="*" --color=fg:#282828,bg:#f9f5d7,hl:#8f3f71,fg+:#282828,bg+:#ebdbb2,hl+:#076678,info:#38694b,prompt:#076678,pointer:#cc241d,marker:#67630c,spinner:#82560e,header:#504945,border:#665c54,preview-border:#665c54,label:#282828'
