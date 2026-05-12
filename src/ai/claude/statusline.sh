#!/usr/bin/env bash
# Claude Code status line — Rose Pine Moon palette
set -euo pipefail

input=$(cat)
cwd=$(echo "$input"    | jq -r '.workspace.current_dir')
model=$(echo "$input"  | jq -r '.model.display_name')
used=$(echo "$input"   | jq -r '.context_window.used_percentage // empty')
in_tok=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(echo "$input"| jq -r '.context_window.total_output_tokens // 0')

branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')
cost=$(echo "scale=2; ($in_tok * 15 + $out_tok * 75) / 1000000" | bc 2>/dev/null || echo '0')
dir=$(basename "$cwd")
tok=$(( (in_tok + out_tok) / 1000 ))

# Rose Pine Moon
iris=$'\033[38;2;196;167;231m'   # model
foam=$'\033[38;2;156;207;216m'   # dir
pine=$'\033[38;2;62;143;176m'    # branch
gold=$'\033[38;2;246;193;119m'   # ctx
love=$'\033[38;2;235;111;146m'   # cost
muted=$'\033[38;2;110;106;134m'  # separators / parens
reset=$'\033[0m'

sep=" ${muted}|${reset} "

out="${iris}${model}${reset}"
out+="${sep}${foam}${dir}${reset}"
[ -n "$branch" ] && out+=" ${muted}(${pine}${branch}${muted})${reset}"

if [ -n "$used" ]; then
    pct=$(printf '%.0f' "$used")
    # Gold → Love as context fills: warn above 70%
    ctx_color="$gold"
    [ "$pct" -ge 70 ] 2>/dev/null && ctx_color="$love"
    out+="${sep}${ctx_color}ctx: ${tok}k (${pct}%)${reset}"
fi

[ "$cost" != "0" ] && [ "$cost" != "0.00" ] && out+="${sep}${love}\$${cost}${reset}"

echo "$out"
