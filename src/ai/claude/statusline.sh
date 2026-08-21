#!/usr/bin/env bash
# Claude Code status line — GitHub Light High Contrast palette + Nerd Fonts (mirrors starship order)
set -euo pipefail

input=$(cat)
cwd=$(echo "$input"      | jq -r '.workspace.current_dir')
model=$(echo "$input"    | jq -r '.model.display_name')
model_id=$(echo "$input" | jq -r '.model.id // empty')
used=$(echo "$input"     | jq -r '.context_window.used_percentage // 0')
in_tok=$(echo "$input"   | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(echo "$input"  | jq -r '.context_window.total_output_tokens // 0')
max_tokens=$(echo "$input" | jq -r '.context_window.max_tokens // 0')

branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')
cost=$(printf '%.2f' "$(echo "scale=4; ($in_tok * 15 + $out_tok * 75) / 1000000" | bc 2>/dev/null || echo '0')")
dir=$(basename "$cwd")
# Derive max context window: prefer JSON field, then parse model ID/name for e.g. [1m] or (200k)
max_k=$(( max_tokens / 1000 ))
if [ "$max_k" -eq 0 ]; then
    for src in "$model_id" "$model"; do
        if [[ "$src" =~ ([0-9]+)([km]) ]]; then
            val="${BASH_REMATCH[1]}"; unit="${BASH_REMATCH[2]}"
            [ "$unit" = "m" ] && max_k=$(( val * 1000 )) || max_k=$val
            break
        fi
    done
fi

# Active skills (up to 10)
skills=$(ls ~/.claude/skills/ 2>/dev/null | head -10 | paste -sd ',' | sed 's/,/, /g')

# GitHub Light High Contrast — same progression as starship: red peach yellow green teal blue
c_red=$'\033[38;2;209;36;47m'      # model      #d1242f
c_peach=$'\033[38;2;112;44;0m'    # dir        #702c00
c_yellow=$'\033[38;2;116;69;0m'   # branch     #744500
c_green=$'\033[38;2;5;93;32m'   # ctx normal #055d20
c_red_warn=$'\033[38;2;209;36;47m' # ctx >= 70% (back to red)
c_teal=$'\033[38;2;27;124;131m'    # cost       #1b7c83
c_blue=$'\033[38;2;3;73;180m'    # skills     #0349b4
c_muted=$'\033[38;2;102;112;123m'    # separators #66707b
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

pct=$(printf '%.0f' "$used")
ctx_color="$c_green"
[ "$pct" -ge 70 ] 2>/dev/null && ctx_color="$c_red_warn"
out+="${sep}${ctx_color}${i_ctx} ${pct}%${reset}"

out+="${sep}${c_teal}${i_cost} \$${cost}${reset}"

[ -n "$skills" ] && out+="${sep}${c_blue}${i_skills} ${skills}${reset}"

echo "$out"
