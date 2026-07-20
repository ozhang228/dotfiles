#!/usr/bin/env bash
# Writes per-pane working/done state to ~/.cache/tmux-agent-status/panes/
# so the sessionizer can show one status icon per running agent.
set -euo pipefail
exec >/dev/null

STATUS_DIR="$HOME/.cache/tmux-agent-status/panes"
mkdir -p "$STATUS_DIR"

HOOK_JSON="$(cat 2>/dev/null || true)"

[ -n "${TMUX:-}" ]      || exit 0
[ -n "${TMUX_PANE:-}" ] || exit 0

SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null) || exit 0
PANE_FILE="$STATUS_DIR/${SESSION}_${TMUX_PANE}.status"

has_running_background_task() {
    [ -n "$1" ] || return 1
    if command -v jq >/dev/null 2>&1; then
        local count
        count=$(printf '%s' "$1" | jq -r '[.background_tasks[]? | select(.status == "running")] | length' 2>/dev/null)
        [ -n "$count" ] && [ "$count" -gt 0 ]
        return
    fi
    case "$1" in
        *'"background_tasks":[]'*) return 1 ;;
        *'"background_tasks":['*'"status":"running"'*) return 0 ;;
        *) return 1 ;;
    esac
}

case "${1:-}" in
    UserPromptSubmit|PreToolUse|PostToolUse)
        echo "working" > "$PANE_FILE"
        ;;
    PermissionRequest)
        echo "wait" > "$PANE_FILE"
        ;;
    Stop)
        if has_running_background_task "$HOOK_JSON"; then
            echo "working" > "$PANE_FILE"
        else
            echo "done" > "$PANE_FILE"
        fi
        ;;
    Notification)
        echo "done" > "$PANE_FILE"
        ;;
esac
