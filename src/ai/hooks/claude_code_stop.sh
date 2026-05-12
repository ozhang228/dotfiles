#!/usr/bin/env bash
# Claude Code Stop hook — sends a dunst notification with colored body
set -euo pipefail

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null || echo '')
[ -z "$cwd" ] && cwd="$PWD"

dir=$(basename "$cwd")
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')

# Icons — same codepoints as status line
i_folder=$'\U000F024B'   # 󰉋 nf-md-folder
i_branch=$''       # U+F418 git branch (explicit codepoint)

# Colors matching status line (Catppuccin Mocha)
peach='#fab387'    # dir
yellow='#f9e2af'   # branch
muted='#7f849c'    # parens / separators
text='#cdd6f4'     # body text

loc="<span foreground='${peach}'>${i_folder} ${dir}</span>"
if [ -n "$branch" ]; then
    loc+=" <span foreground='${muted}'>(</span><span foreground='${yellow}'>${i_branch} ${branch}</span><span foreground='${muted}'>)</span>"
fi

body="${loc}
<span foreground='${text}'>claude code finished</span>"

notify-send -u low -a "Kitty" 'Claude Code' "$body" 2>/dev/null || true
