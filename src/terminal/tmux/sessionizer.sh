#!/usr/bin/env bash
# Fuzzy-pick an existing tmux session or a project directory, and
# switch-or-create a tmux session for it.
#
# - Existing sessions show as "name [branch] <agent>".
# - Project directories without a matching session show as "name [branch]".
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

    agent_icons() {
        local session="$1"
        local pane_dir="$HOME/.cache/tmux-agent-status/panes"
        [ -d "$pane_dir" ] || return 0
        local active_panes icons=()
        active_panes=$(tmux list-panes -t "$session" -F '#{pane_id}' 2>/dev/null || true)
        for f in "$pane_dir/${session}_"*.status; do
            [ -f "$f" ] || continue
            local pane_id
            pane_id=$(basename "$f" .status)
            pane_id="${pane_id#${session}_}"
            printf '%s\n' "$active_panes" | grep -qx "$pane_id" || continue
            case "$(cat "$f" 2>/dev/null)" in
                working) icons+=("⚡") ;;
                done)    icons+=("✅") ;;
                wait)    icons+=("⏸") ;;
            esac
        done
        [ "${#icons[@]}" -gt 0 ] && printf '%s' "${icons[*]}"
    }

    entries=()
    for name in "${!session_activity[@]}"; do
        [ "$name" = "$cur_session" ] && continue
        path="${session_path[$name]}"
        branch=$(git -C "$path" branch --show-current 2>/dev/null || true)
        agent=$(agent_icons "$name")
        label="$name"
        [ -n "$branch" ] && label="$label [$branch]"
        [ -n "$agent" ]  && label="$label $agent"
        entries+=("${session_activity[$name]}"$'\t'session$'\t'"$name"$'\t'"$label")
    done

    for dir in "${candidates[@]}"; do
        name=$(basename "$dir" | tr '.:' '__')
        [ -n "${session_activity[$name]+x}" ] && continue
        branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)
        label="$name"
        [ -n "$branch" ] && label="$label [$branch]"
        entries+=("0"$'\t'dir$'\t'"$dir"$'\t'"$label")
    done

    printf '%s\n' "${entries[@]}" | sort -t $'\t' -k1,1 -rn
}

if [ "${1:-}" = "--list" ]; then
    list_entries
    exit 0
fi

if [ "${1:-}" = "--preview" ]; then
    kind="$2"
    key="$3"
    if [ "$kind" = "session" ]; then
        tmux capture-pane -e -p -t "$key"
    else
        ls -la --color=always "$key"
        if git -C "$key" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo
            git -C "$key" log --oneline --color=always -10
        fi
    fi
    exit 0
fi

selected=$(list_entries | fzf \
    --delimiter $'\t' --with-nth=4 \
    --bind "ctrl-x:execute-silent(tmux kill-session -t {3} 2>/dev/null)+reload($SCRIPT --list)" \
    --preview "$SCRIPT --preview {2} {3}" \
    --preview-window right:60%)

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
