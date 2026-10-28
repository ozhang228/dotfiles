#!/usr/bin/env bash
# lazygit git.branchLogCmd: summarize divergence from main/master and list the changed files.
set -euo pipefail

branch=${1:?usage: branch-log.sh <branch>}

# Catppuccin Macchiato, matching gui.theme in config.yml.
readonly SUBTEXT='\e[38;2;165;173;203m' TEAL='\e[38;2;139;213;202m' YELLOW='\e[38;2;238;212;159m'
readonly GREEN='\e[38;2;166;218;149m' RED='\e[38;2;237;135;150m' RESET='\e[0m'

stat_base=
for base in main master; do
  git rev-parse --quiet --verify "refs/heads/$base" >/dev/null || continue
  [[ $(git rev-parse "$base") == $(git rev-parse "$branch") ]] && continue
  read -r behind ahead < <(git rev-list --left-right --count "$base...$branch")
  read -r added deleted files < <(git diff --numstat "$base...$branch" |
    awk '{ if ($1 != "-") { a += $1; d += $2 } f++ } END { print a + 0, d + 0, f + 0 }')
  printf "${SUBTEXT}vs %s${RESET}  ${TEAL}↑%d${RESET} ${YELLOW}↓%d${RESET}  ${GREEN}+%d${RESET} ${RED}−%d${RESET}  ${SUBTEXT}%d files${RESET}\n" \
    "$base" "$ahead" "$behind" "$added" "$deleted" "$files"
  stat_base=${stat_base:-$base}
done

if [[ -z $stat_base ]]; then
  git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium "$branch" --
  exit
fi

printf '\n'
git -c color.diff.new='#a6da95' -c color.diff.old='#ed8796' \
  diff --stat --color=always --stat-width=100 "$stat_base...$branch" | sed '$d'
