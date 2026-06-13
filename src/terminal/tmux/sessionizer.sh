#!/usr/bin/env bash
# Fuzzy-pick a project directory and create-or-switch to a tmux session
# named after it. Shows "dir [branch]" and sorts by most-recently-used
# tmux session first.
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

cwd=$(realpath "$PWD")
filtered=()
for dir in "${candidates[@]}"; do
    [ "$(realpath "$dir")" != "$cwd" ] && filtered+=("$dir")
done
candidates=("${filtered[@]}")

declare -A activity
while IFS=$'\t' read -r name ts; do
    activity["$name"]="$ts"
done < <(tmux list-sessions -F '#{session_name}	#{session_activity}' 2>/dev/null)

entries=()
for dir in "${candidates[@]}"; do
    name=$(basename "$dir" | tr '.:' '__')
    branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)
    label="$dir"
    [ -n "$branch" ] && label="$dir [$branch]"
    entries+=("${activity[$name]:-0}"$'\t'"$dir"$'\t'"$label")
done

selected_dir=$(printf '%s\n' "${entries[@]}" \
    | sort -t $'\t' -k1,1 -rn \
    | cut -f2- \
    | fzf --delimiter $'\t' --with-nth=2 \
    | cut -f1)

[ -z "$selected_dir" ] && exit 0

session_name=$(basename "$selected_dir" | tr '.:' '__')

if ! tmux has-session -t "$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$selected_dir"
fi

if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session_name"
else
    tmux attach-session -t "$session_name"
fi
