#!/usr/bin/env bash
# Claude Code Notification hook — fires on permission prompts and idle waits
set -euo pipefail

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null || echo '')
[ -z "$cwd" ] && cwd="$PWD"
message=$(echo "$input" | jq -r '.message // "needs your attention"' 2>/dev/null || echo "needs your attention")

dir=$(basename "$cwd")
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')

# Icons
i_folder=$'\U000F024B'   # 󰉋 nf-md-folder
i_branch=$''       # U+F418 git branch

# Colors
peach='#fab387'
yellow='#f9e2af'
muted='#7f849c'
text='#cdd6f4'

loc="<span foreground='${peach}'>${i_folder} ${dir}</span>"
if [ -n "$branch" ]; then
    loc+=" <span foreground='${muted}'>(</span><span foreground='${yellow}'>${i_branch} ${branch}</span><span foreground='${muted}'>)</span>"
fi

body="${loc}
<span foreground='${text}'>${message}</span>"

# Different summary so dunst can match a separate rule with a different sound
notify-send -u normal -a "Kitty" 'Claude Code (waiting)' "$body" 2>/dev/null || true
