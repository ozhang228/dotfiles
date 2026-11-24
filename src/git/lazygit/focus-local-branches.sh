#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${TMUX_PANE:-}" ]] || ! command -v tmux >/dev/null; then
  exit 0
fi

tmux run-shell -b "sleep 0.1; tmux send-keys -t '$TMUX_PANE' C-q '['"
