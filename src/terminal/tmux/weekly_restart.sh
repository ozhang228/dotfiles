#!/usr/bin/env bash
# Run weekly via cron/systemd timer. Warns every attached tmux client, waits
# a grace period, then kills the server unless skipped.
# To skip a scheduled restart: touch ~/.cache/tmux-skip-restart
set -euo pipefail

GRACE_SECONDS=300
SKIP_FILE="$HOME/.cache/tmux-skip-restart"

tmux list-sessions >/dev/null 2>&1 || exit 0

tmux display-message -a "tmux will restart in $((GRACE_SECONDS / 60)) minutes for the weekly refresh. Run 'touch $SKIP_FILE' to skip this week."
sleep "$GRACE_SECONDS"

tmux list-sessions >/dev/null 2>&1 || exit 0

if [ -f "$SKIP_FILE" ]; then
    rm -f "$SKIP_FILE"
    tmux display-message -a "Weekly tmux restart skipped." 2>/dev/null || true
    exit 0
fi

tmux display-message -a "Restarting tmux now." 2>/dev/null || true
sleep 2
tmux kill-server
