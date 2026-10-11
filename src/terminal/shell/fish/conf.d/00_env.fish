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

# Catppuccin Macchiato — keeps fzf's own picker readable against the dark terminal bg
set -e FZF_DEFAULT_OPTS
set -gx FZF_DEFAULT_OPTS_FILE "$HOME/dotfiles/src/terminal/fzf/opts"
