#!/usr/bin/env bash
set -euo pipefail

selected=${1:?Expected selected branch}
destination=${2:?Expected current branch}

if [[ $(git symbolic-ref --quiet --short HEAD) != "$destination" ]]; then
  printf 'Current branch changed; reopen the merge confirmation.\n' >&2
  exit 1
fi

git fetch --all --quiet
target="refs/heads/$selected"

if [[ "$selected" == "$destination" ]]; then
  target=
  for branch in main master; do
    upstream=$(git rev-parse --verify --symbolic-full-name "$branch@{upstream}" 2>/dev/null || true)
    if [[ "$upstream" == refs/remotes/* ]]; then
      target=$upstream
      break
    fi
  done

  if [[ -z "$target" ]]; then
    candidate_count=0
    while IFS= read -r candidate; do
      target=$candidate
      candidate_count=$((candidate_count + 1))
    done < <(git for-each-ref --format='%(refname)' \
      'refs/remotes/*/main' 'refs/remotes/*/master')
    case $candidate_count in
      1) ;;
      0)
        for branch in main master; do
          if git show-ref --verify --quiet "refs/heads/$branch"; then
            target="refs/heads/$branch"
            break
          fi
        done
        if [[ -z "$target" ]]; then
          printf 'No main or master branch found.\n' >&2
          exit 1
        fi
        ;;
      *)
        printf 'Multiple remote main/master branches found; set the upstream of local main/master.\n' >&2
        exit 1
        ;;
    esac
  fi
fi

git merge --no-edit -- "$target"
