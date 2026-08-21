# pnpm
set -gx PNPM_HOME "/home/ozhang/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

set -gx AI_CLI_CMD "claude-branch-resume --dangerously-skip-permissions || claude --dangerously-skip-permissions"
set -gx ANTHROPIC_MODEL sonnet

tmux_autostart
