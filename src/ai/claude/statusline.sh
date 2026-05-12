#!/usr/bin/env bash
# Claude Code status line — Catppuccin Mocha palette + Nerd Fonts (mirrors starship order)
set -euo pipefail

input=$(cat)
cwd=$(echo "$input"    | jq -r '.workspace.current_dir')
model=$(echo "$input"  | jq -r '.model.display_name')
used=$(echo "$input"   | jq -r '.context_window.used_percentage // empty')
in_tok=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(echo "$input"| jq -r '.context_window.total_output_tokens // 0')

branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')
cost=$(printf '%.2f' "$(echo "scale=4; ($in_tok * 15 + $out_tok * 75) / 1000000" | bc 2>/dev/null || echo '0')")
dir=$(basename "$cwd")
tok=$(( (in_tok + out_tok) / 1000 ))

# Derive max context window size from model name e.g. "claude-sonnet-4-6 (1m)"
max_k=0
if [[ "$model" =~ \(?([0-9]+)([km])\)? ]]; then
    val="${BASH_REMATCH[1]}"; unit="${BASH_REMATCH[2]}"
    [ "$unit" = "m" ] && max_k=$(( val * 1000 )) || max_k=$val
fi

# Active skills (up to 10)
skills=$(ls ~/.claude/skills/ 2>/dev/null | head -10 | paste -sd ',' | sed 's/,/, /g')

# Catppuccin Mocha — same progression as starship: red peach yellow green teal blue
c_red=$'\033[38;2;243;139;168m'      # model      #f38ba8
c_peach=$'\033[38;2;250;179;135m'    # dir        #fab387
c_yellow=$'\033[38;2;249;226;175m'   # branch     #f9e2af
c_green=$'\033[38;2;166;227;161m'    # ctx normal #a6e3a1
c_red_warn=$'\033[38;2;243;139;168m' # ctx >= 70% (back to red)
c_teal=$'\033[38;2;148;226;213m'     # cost       #94e2d5
c_blue=$'\033[38;2;137;180;250m'     # skills     #89b4fa
c_muted=$'\033[38;2;127;132;156m'    # separators #7f849c (overlay1)
reset=$'\033[0m'

# Nerd Font icons — branch is U+F418 (matches starship config)
i_branch=$''
i_robot='󰚩'
i_folder='󰉋'
i_ctx='󰍛'
i_cost='󱖨'
i_skills='󰘦'

sep=" ${c_muted}|${reset} "

out="${c_red}${i_robot} ${model}${reset}"
out+="${sep}${c_peach}${i_folder} ${dir}${reset}"
[ -n "$branch" ] && out+=" ${c_muted}(${c_yellow}${i_branch} ${branch}${c_muted})${reset}"

if [ -n "$used" ]; then
    pct=$(printf '%.0f' "$used")
    ctx_color="$c_green"
    [ "$pct" -ge 70 ] 2>/dev/null && ctx_color="$c_red_warn"
    if [ "$max_k" -gt 0 ]; then
        out+="${sep}${ctx_color}${i_ctx} ${tok}k/${max_k}k (${pct}%)${reset}"
    else
        out+="${sep}${ctx_color}${i_ctx} ${tok}k (${pct}%)${reset}"
    fi
fi

out+="${sep}${c_teal}${i_cost} \$${cost}${reset}"

[ -n "$skills" ] && out+="${sep}${c_blue}${i_skills} ${skills}${reset}"

echo "$out"
