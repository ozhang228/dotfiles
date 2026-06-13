#!/usr/bin/env bash
# Fuzzy-pick a project directory and create-or-switch to a tmux session
# named after it.
set -euo pipefail

candidates=()

for root in ~/forge ~/dotfiles; do
    [ -d "$root" ] && candidates+=("$root")
done

if [ -d ~/drw ]; then
    for d in ~/drw/*/; do
        [ -d "$d" ] && candidates+=("${d%/}")
    done
fi

selected=$(printf '%s\n' "${candidates[@]}" | fzf) || exit 0

session_name=$(basename "$selected" | tr '.:' '__')

if ! tmux has-session -t "$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$selected"
fi

if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session_name"
else
    tmux attach-session -t "$session_name"
fi
