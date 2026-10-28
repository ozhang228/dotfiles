#!/usr/bin/env bash
# Run weekly by tmux-weekly-restart.timer (setup/scripts/tmux-weekly-restart.sh).
# Warns every attached tmux client, waits a grace period, then closes every
# session unless skipped. Closing sessions instead of kill-server lets the
# session-closed hook stop each session's background processes.
# To skip a scheduled restart: touch ~/.cache/tmux-skip-restart
set -euo pipefail

GRACE_SECONDS=300
SKIP_FILE="$HOME/.cache/tmux-skip-restart"

notify_clients() {
    local client
    tmux list-clients -F '#{client_name}' 2>/dev/null | while IFS= read -r client; do
        tmux display-message -c "$client" -d 15000 "$1" 2>/dev/null || true
    done
}

tmux list-sessions >/dev/null 2>&1 || exit 0

notify_clients "tmux will restart in $((GRACE_SECONDS / 60)) minutes for the weekly refresh. Run 'touch $SKIP_FILE' to skip this week."
sleep "$GRACE_SECONDS"

tmux list-sessions >/dev/null 2>&1 || exit 0

if [ -f "$SKIP_FILE" ]; then
    rm -f "$SKIP_FILE"
    notify_clients "Weekly tmux restart skipped."
    exit 0
fi

notify_clients "Restarting tmux now."
sleep 2
tmux set-option -g detach-on-destroy on
tmux list-sessions -F '#{session_id}' | while IFS= read -r session; do
    tmux kill-session -t "$session" 2>/dev/null || true
done
