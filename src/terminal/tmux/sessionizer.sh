#!/usr/bin/env bash
# Fuzzy-pick an existing tmux session or a project directory, and
# switch-or-create a tmux session for it.
#
# - Existing sessions show as "name (path) [branch]".
# - Project directories without a matching session show as "path [branch]".
# - Entries are sorted by most-recently-active session first.
# - ctrl-x kills the session under the cursor and refreshes the list.
set -euo pipefail

SCRIPT=$(realpath "$0")

list_entries() {
    candidates=()
    for root in ~/forge ~/dotfiles; do
        [ -d "$root" ] && candidates+=("$root")
    done

    if [ -d ~/drw ]; then
        for d in ~/drw/*/; do
            [ -d "$d" ] && candidates+=("${d%/}")
        done
    fi

    declare -A session_activity
    declare -A session_path
    while IFS=$'\t' read -r name ts path; do
        session_activity["$name"]="$ts"
        session_path["$name"]="$path"
    done < <(tmux list-sessions -F '#{session_name}	#{session_activity}	#{session_path}' 2>/dev/null)

    cur_session=""
    [ -n "${TMUX:-}" ] && cur_session=$(tmux display-message -p '#{session_name}')

    entries=()
    for name in "${!session_activity[@]}"; do
        [ "$name" = "$cur_session" ] && continue
        path="${session_path[$name]}"
        branch=$(git -C "$path" branch --show-current 2>/dev/null || true)
        label="$name  ($path)"
        [ -n "$branch" ] && label="$label [$branch]"
        entries+=("${session_activity[$name]}"$'\t'session$'\t'"$name"$'\t'"$label")
    done

    for dir in "${candidates[@]}"; do
        name=$(basename "$dir" | tr '.:' '__')
        [ -n "${session_activity[$name]+x}" ] && continue
        branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)
        label="$dir"
        [ -n "$branch" ] && label="$dir [$branch]"
        entries+=("0"$'\t'dir$'\t'"$dir"$'\t'"$label")
    done

    printf '%s\n' "${entries[@]}" | sort -t $'\t' -k1,1 -rn
}

if [ "${1:-}" = "--list" ]; then
    list_entries
    exit 0
fi

selected=$(list_entries | fzf \
    --delimiter $'\t' --with-nth=4 \
    --bind "ctrl-x:execute-silent(tmux kill-session -t {3} 2>/dev/null)+reload($SCRIPT --list)")

[ -z "$selected" ] && exit 0

kind=$(printf '%s' "$selected" | cut -f2)
key=$(printf '%s' "$selected" | cut -f3)

if [ "$kind" = "session" ]; then
    session_name="$key"
else
    session_name=$(basename "$key" | tr '.:' '__')
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$key"
    fi
fi

if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session_name"
else
    tmux attach-session -t "$session_name"
fi
