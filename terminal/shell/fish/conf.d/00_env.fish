fish_add_path "$HOME/.local/bin"

set -gx EDITOR "nvim"
set -gx AI_CLI_CMD "claude --resume || claude"

# C/C++ compiler and vcpkg
set -gx CC "clang"
set -gx CXX "clang++"
set -gx VCPKG_ROOT "$HOME/.local/vcpkg"
