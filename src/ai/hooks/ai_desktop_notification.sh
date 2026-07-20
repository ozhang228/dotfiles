#!/usr/bin/env bash
set -euo pipefail
exec >/dev/null

input=$(cat)

json_value() {
    printf '%s' "$input" | jq -r "$1" 2>/dev/null || true
}

escape_markup() {
    printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

cwd=$(json_value '.workspace.current_dir // .cwd // empty')
[ -n "$cwd" ] || cwd="$PWD"
repo=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$repo" ] || repo="$cwd"

dir=$(escape_markup "$(basename "$cwd")")
raw_branch=$(git -C "$repo" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || true)
display_branch=$(escape_markup "$raw_branch")

peach='#fab387'
yellow='#f9e2af'
muted='#7f849c'
text='#cdd6f4'

loc="<span foreground='${peach}'>${dir}</span>"
if [ -n "$display_branch" ]; then
    loc+=" <span foreground='${muted}'>(</span><span foreground='${yellow}'>${display_branch}</span><span foreground='${muted}'>)</span>"
fi

case "${1:-notification}" in
    stop)
        session_id=$(json_value '.session_id // empty')
        if [ -n "${AI_BRANCH_SESSION_DIR:-}" ] && [ -n "$session_id" ] && [ -n "$raw_branch" ]; then
            remote=$(git -C "$repo" config --get remote.origin.url 2>/dev/null || true)
            [ -n "$remote" ] || remote="$repo"
            branch_key=$(printf '%s:%s' "$remote" "$raw_branch" | sha1sum | cut -c1-12)
            mkdir -p "$AI_BRANCH_SESSION_DIR"
            printf '%s\n' "$session_id" > "$AI_BRANCH_SESSION_DIR/$branch_key"
        fi
        title='AI Assistant'
        urgency='low'
        message='finished'
        ;;
    notification)
        title='AI Assistant (waiting)'
        urgency='normal'
        message=$(json_value '.message // empty')
        [ -n "$message" ] || message='needs your attention'
        message=$(escape_markup "$message")
        ;;
    *)
        exit 0
        ;;
esac

body="${loc}
<span foreground='${text}'>${message}</span>"

timeout 2s notify-send -u "$urgency" -a 'AI Assistant' "$title" "$body" 2>/dev/null || true
