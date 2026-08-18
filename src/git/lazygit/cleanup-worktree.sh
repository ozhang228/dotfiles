#!/usr/bin/env bash
set -euo pipefail

worktree_arg=${1-}
branch_arg=${2-}

if [[ -z "$worktree_arg" ]]; then
  printf 'usage: cleanup-worktree.sh <branch> | <worktree-path> <branch>\n' >&2
  exit 1
fi

if [[ -z "$branch_arg" ]]; then
  branch_arg=$worktree_arg
  repo=$(git rev-parse --show-toplevel)
  worktree_arg=$(git -C "$repo" worktree list --porcelain | awk -v ref="refs/heads/$branch_arg" '
    /^worktree / { worktree = substr($0, 10) }
    $0 == "branch " ref { print worktree }
  ')
  if [[ -z "$worktree_arg" ]]; then
    printf 'No worktree is registered for branch %q.\n' "$branch_arg" >&2
    exit 1
  fi
fi

if [[ ! -d "$worktree_arg" ]]; then
  printf 'Refusing missing worktree path: %s\n' "$worktree_arg" >&2
  exit 1
fi

current_worktree=$(realpath -e "$(git rev-parse --show-toplevel)")
worktree=$(realpath -e "$worktree_arg")
main_worktree=$(git -C "$worktree" worktree list --porcelain | awk '/^worktree / { print substr($0, 10); exit }')
main_worktree=$(realpath -e "$main_worktree")
main_parent=$(dirname "$main_worktree")
main_basename=$(basename "$main_worktree")
worktree_basename=$(basename "$worktree")

if [[ "$worktree" == "$main_worktree" || "$worktree" == "$current_worktree" ]]; then
  printf 'Refusing to remove the main or current worktree: %s\n' "$worktree" >&2
  exit 1
fi

if [[ "$(dirname "$worktree")" != "$main_parent" || "$worktree_basename" != "$main_basename"-* ]]; then
  printf 'Refusing worktree outside expected sibling path: %s\n' "$worktree" >&2
  exit 1
fi

if ! git -C "$main_worktree" worktree list --porcelain | sed -n 's/^worktree //p' | grep -Fqx -- "$worktree"; then
  printf 'Refusing unregistered worktree: %s\n' "$worktree" >&2
  exit 1
fi

branch=$(git -C "$worktree" branch --show-current)
if [[ -z "$branch" ]]; then
  printf 'Refusing to remove a detached worktree: %s\n' "$worktree" >&2
  exit 1
fi

if [[ "$branch" != "$branch_arg" ]]; then
  printf 'Branch mismatch for %s: expected %q, found %q.\n' "$worktree" "$branch_arg" "$branch" >&2
  exit 1
fi

if [[ -n "$(git -C "$worktree" status --porcelain --ignored=matching)" ]]; then
  printf 'Refusing to remove dirty, untracked, or ignored files from worktree: %s\n' "$worktree" >&2
  exit 1
fi

recovery_refs=(HEAD)
if upstream=$(git -C "$worktree" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null); then
  recovery_refs+=("$upstream")
fi
for ref in main master origin/main origin/master; do
  if git -C "$main_worktree" rev-parse --verify --quiet "$ref^{commit}" >/dev/null; then
    recovery_refs+=("$ref")
  fi
done

remaining_commit=$(git -C "$main_worktree" rev-list --max-count=1 "$branch" --not "${recovery_refs[@]}" --remotes)
if [[ -n "$remaining_commit" ]]; then
  if [[ "${LAZYGIT_CLEANUP_CONFIRMED:-}" != "1" ]]; then
    printf 'WARNING: %q has unmerged or unpushed commits. Remove its worktree and local branch? [y/N] ' "$branch" >&2
    read -r answer
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
      printf 'Cleanup cancelled.\n' >&2
      exit 1
    fi
  fi
fi

percent_encode_session_name() {
  local value=$1
  local char encoded

  for char in '%' / \\ : '*' '?' '"' "'" '<' '>' '+' ' ' '|' '.'; do
    printf -v encoded '%%%02X' "'$char"
    value=${value//"$char"/"$encoded"}
  done
  printf '%s\n' "$value"
}

session_root=${XDG_DATA_HOME:-"$HOME/.local/share"}/nvim/sessions
current_session_name=$(percent_encode_session_name "$worktree")
legacy_session_name=${worktree//\//%}

git -C "$main_worktree" worktree remove "$worktree"
git -C "$main_worktree" branch -D "$branch"

if command -v tmux >/dev/null && tmux has-session -t "=$worktree_basename" 2>/dev/null; then
  tmux kill-session -t "=$worktree_basename"
fi
rm -f -- "$session_root/$current_session_name.vim" "$session_root/$legacy_session_name.vim"
