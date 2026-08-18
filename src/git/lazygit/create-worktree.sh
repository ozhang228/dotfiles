#!/usr/bin/env bash
set -euo pipefail

mode=${1-}
branch=
base=
remote=

case "$mode" in
  existing)
    branch=${2-}
    ;;
  new)
    branch=${2-}
    base=${3-}
    ;;
  remote)
    remote=${2-}
    branch=${3-}
    ;;
  *)
    printf 'Unknown create mode: %q.\n' "$mode" >&2
    exit 1
    ;;
esac

if [[ -z "$branch" || ( "$mode" == "new" && -z "$base" ) || ( "$mode" == "remote" && -z "$remote" ) ]]; then
  printf 'usage: create-worktree.sh existing <branch> | new <branch> <base> | remote <remote> <branch>\n' >&2
  exit 1
fi

repo=$(git rev-parse --show-toplevel)
main_worktree=$(git -C "$repo" worktree list --porcelain | awk '/^worktree / { print substr($0, 10); exit }')
main_worktree=$(realpath -e "$main_worktree")

case "$branch" in
  main|master)
    printf 'Refusing to create a feature worktree for %q.\n' "$branch" >&2
    exit 1
    ;;
esac

if ! git check-ref-format --branch "$branch" >/dev/null; then
  printf 'Invalid branch name: %q.\n' "$branch" >&2
  exit 1
fi

feature_slug=$branch
if [[ -n "${USER:-}" && "$feature_slug" == "$USER/"* ]]; then
  feature_slug=${feature_slug#"$USER/"}
fi
feature_slug=${feature_slug//\//-}

target=$(dirname "$main_worktree")/$(basename "$main_worktree")-$feature_slug

if [[ -e "$target" || -L "$target" ]]; then
  printf 'Refusing to overwrite existing path: %s\n' "$target" >&2
  exit 1
fi

if git -C "$main_worktree" worktree list --porcelain | grep -Fqx "branch refs/heads/$branch"; then
  printf 'Branch %q is already checked out in a worktree.\n' "$branch" >&2
  exit 1
fi

case "$mode" in
  existing)
    if ! git -C "$main_worktree" show-ref --verify --quiet "refs/heads/$branch"; then
      printf 'Local branch does not exist: %q.\n' "$branch" >&2
      exit 1
    fi
    git -C "$main_worktree" worktree add "$target" "$branch"
    ;;
  new)
    if ! git -C "$main_worktree" show-ref --verify --quiet "refs/heads/$base"; then
      printf 'Local base branch does not exist: %q.\n' "$base" >&2
      exit 1
    fi
    if git -C "$main_worktree" show-ref --verify --quiet "refs/heads/$branch"; then
      printf 'Local branch already exists: %q.\n' "$branch" >&2
      exit 1
    fi
    git -C "$main_worktree" worktree add -b "$branch" "$target" "$base"
    ;;
  remote)
    remote_branch="$remote/$branch"
    if ! git -C "$main_worktree" show-ref --verify --quiet "refs/remotes/$remote/$branch"; then
      printf 'Remote branch does not exist: %q.\n' "$remote_branch" >&2
      exit 1
    fi

    if git -C "$main_worktree" show-ref --verify --quiet "refs/heads/$branch"; then
      upstream=$(git -C "$main_worktree" rev-parse --abbrev-ref --symbolic-full-name "$branch@{upstream}" 2>/dev/null || true)
      if [[ "$upstream" != "$remote_branch" ]]; then
        printf 'Local branch %q must track %q, found %q.\n' "$branch" "$remote_branch" "${upstream:-no upstream}" >&2
        exit 1
      fi

      if git -C "$main_worktree" merge-base --is-ancestor "$branch" "$remote_branch"; then
        git -C "$main_worktree" branch -f "$branch" "$remote_branch" >/dev/null
      elif ! git -C "$main_worktree" merge-base --is-ancestor "$remote_branch" "$branch"; then
        printf 'Local branch %q has diverged from %q. Reconcile it before creating a worktree.\n' \
          "$branch" "$remote_branch" >&2
        exit 1
      fi
      git -C "$main_worktree" worktree add "$target" "$branch"
    else
      git -C "$main_worktree" worktree add --track -b "$branch" "$target" "$remote_branch"
    fi
    ;;
esac
