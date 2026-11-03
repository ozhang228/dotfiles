# pnpm
set -gx PNPM_HOME "/home/ozhang/.local/share/pnpm"
fish_add_path $PNPM_HOME/bin $PNPM_HOME
# pnpm end

set -gx AI_CLI_CMD "claude-worktree-resume --dangerously-skip-permissions"

tmux_autostart
