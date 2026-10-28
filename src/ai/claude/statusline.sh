#!/usr/bin/env bash
# Claude Code status line — Catppuccin Macchiato palette + Nerd Fonts (mirrors starship order)
set -euo pipefail

input=$(cat)
mapfile -d '' -t fields < <(jq -jr '
  [
    .workspace.current_dir // "",
    .model.display_name // "",
    .context_window.used_percentage // 0,
    (.cost.total_cost_usd // (((.context_window.total_input_tokens // 0) * 15 + (.context_window.total_output_tokens // 0) * 75) / 1000000))
  ] | map(tostring + "\u0000") | join("")
' <<< "$input")
if [ "${#fields[@]}" -ne 4 ]; then
    echo "Invalid Claude status input" >&2
    exit 1
fi
cwd=${fields[0]}
model=${fields[1]}
used=${fields[2]}
printf -v cost '%.2f' "${fields[3]}"

branch=''
if [ -d "$cwd" ]; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || true)
fi
dir=${cwd##*/}

skills=''
skill_count=0
for skill_file in "$HOME"/.claude/skills/*/SKILL.md; do
    [ -f "$skill_file" ] || continue
    skill_name=${skill_file%/SKILL.md}
    skill_name=${skill_name##*/}
    if [ -n "$skills" ]; then
        skills+=", $skill_name"
    else
        skills=$skill_name
    fi
    skill_count=$((skill_count + 1))
    if [ "$skill_count" -ge 10 ]; then break; fi
done

# Catppuccin Macchiato — same progression as starship: red peach yellow green teal blue
c_red=$'\033[38;2;238;153;160m'      # model      #ee99a0
c_peach=$'\033[38;2;245;169;127m'    # dir        #f5a97f
c_yellow=$'\033[38;2;238;212;159m'   # branch     #eed49f
c_green=$'\033[38;2;166;218;149m'   # ctx normal #a6da95
c_red_warn=$'\033[38;2;237;135;150m' # ctx >= 70% (back to red)
c_teal=$'\033[38;2;139;213;202m'    # cost       #8bd5ca
c_blue=$'\033[38;2;138;173;244m'    # skills     #8aadf4
c_muted=$'\033[38;2;147;154;183m'    # separators #939ab7
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
