set -gx AI_CLI_CMD "claude-branch-resume || claude"

# pnpm
fish_add_path $HOME/.local/share/pnpm

# >>> conda initialize >>>
if test -f /home/ozhang/miniconda3/bin/conda
    eval /home/ozhang/miniconda3/bin/conda "shell.fish" "hook" $argv | source
end
# <<< conda initialize <<<
