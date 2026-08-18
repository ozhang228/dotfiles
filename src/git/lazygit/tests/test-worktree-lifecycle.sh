#!/usr/bin/env bash
set -euo pipefail

readonly LAZYGIT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
readonly CREATE_WORKTREE="$LAZYGIT_DIR/create-worktree.sh"
readonly CLEANUP_WORKTREE="$LAZYGIT_DIR/cleanup-worktree.sh"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_exists() {
  [[ -e "$1" ]] || fail "expected path to exist: $1"
}

assert_missing() {
  [[ ! -e "$1" ]] || fail "expected path to be absent: $1"
}

assert_branch_exists() {
  git -C "$1" show-ref --verify --quiet "refs/heads/$2" || fail "expected branch to exist: $2"
}

assert_branch_missing() {
  ! git -C "$1" show-ref --verify --quiet "refs/heads/$2" || fail "expected branch to be absent: $2"
}

new_test_root() {
  mktemp -d "/tmp/lazygit worktree.XXXXXX"
}

current_session_file() {
  local encoded=$1
  encoded=${encoded//%/%25}
  encoded=${encoded//\//%2F}
  encoded=${encoded// /%20}
  encoded=${encoded//./%2E}
  printf '%s/nvim/sessions/%s.vim\n' "$XDG_DATA_HOME" "$encoded"
}

legacy_session_file() {
  local encoded=${1//\//%}
  printf '%s/nvim/sessions/%s.vim\n' "$XDG_DATA_HOME" "$encoded"
}

create_session_files() {
  local worktree=$1
  local current legacy
  current=$(current_session_file "$worktree")
  legacy=$(legacy_session_file "$worktree")

  mkdir -p "$(dirname "$current")"
  touch "$current" "$legacy"
}

new_repository() {
  local root=$1
  local repo=$root/desk-tools
  local remote=$root/remote.git

  git init --initial-branch=main "$repo" >/dev/null
  git -C "$repo" config user.name Test
  git -C "$repo" config user.email test@example.com
  printf 'base\n' >"$repo/base.txt"
  git -C "$repo" add base.txt
  git -C "$repo" commit -m base >/dev/null
  git init --bare --initial-branch=main "$remote" >/dev/null
  git -C "$repo" remote add origin "$remote"
  git -C "$repo" push -u origin main >/dev/null
  printf '%s\n' "$repo"
}

create_feature_worktree() {
  local repo=$1
  local branch=$2

  git -C "$repo" branch "$branch"
  (
    cd "$repo"
    "$CREATE_WORKTREE" existing "$branch" >/dev/null
  )
}

create_remote_branch() {
  local repo=$1
  local branch=$2

  git -C "$repo" switch -c "$branch" >/dev/null
  printf 'remote branch\n' >"$repo/remote.txt"
  git -C "$repo" add remote.txt
  git -C "$repo" commit -m "remote branch" >/dev/null
  git -C "$repo" push -u origin "$branch" >/dev/null
  git -C "$repo" switch main >/dev/null
  git -C "$repo" branch -D "$branch" >/dev/null
}

create_remote_worktree() {
  local repo=$1
  local branch=$2

  (
    cd "$repo"
    "$CREATE_WORKTREE" remote origin "$branch" >/dev/null
  )
}

advance_remote_branch() {
  local repo=$1
  local branch=$2
  local contents=$3

  git -C "$repo" switch --detach "origin/$branch" >/dev/null
  printf '%s\n' "$contents" >"$repo/remote-update.txt"
  git -C "$repo" add remote-update.txt
  git -C "$repo" commit -m "advance remote branch" >/dev/null
  git -C "$repo" push origin "HEAD:$branch" >/dev/null
  git -C "$repo" switch main >/dev/null
}

test_new_branch_uses_selected_base() {
  local root repo base branch worktree base_commit
  root=$(new_test_root)
  repo=$(new_repository "$root")
  base=feature/selected-base
  branch="$USER/feature/from-selected-base"
  worktree="$root/desk-tools-feature-from-selected-base"

  git -C "$repo" switch -c "$base" >/dev/null
  printf 'selected base\n' >"$repo/selected-base.txt"
  git -C "$repo" add selected-base.txt
  git -C "$repo" commit -m "selected base" >/dev/null
  base_commit=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" switch main >/dev/null

  (
    cd "$repo"
    "$CREATE_WORKTREE" new "$branch" "$base" >/dev/null
  )

  assert_exists "$worktree"
  assert_branch_exists "$repo" "$branch"
  [[ "$(git -C "$worktree" rev-parse HEAD)" == "$base_commit" ]] || fail "new branch did not use selected base"
  assert_exists "$worktree/selected-base.txt"
  rm -rf "$root"
}

test_remote_branch_creates_tracking_worktree() {
  local root repo branch worktree remote_commit
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/remote-new
  worktree="$root/desk-tools-feature-remote-new"
  create_remote_branch "$repo" "$branch"
  remote_commit=$(git -C "$repo" rev-parse "refs/remotes/origin/$branch")

  create_remote_worktree "$repo" "$branch"

  assert_exists "$worktree"
  [[ "$(git -C "$worktree" rev-parse HEAD)" == "$remote_commit" ]] || fail "remote worktree has wrong commit"
  [[ "$(git -C "$worktree" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')" == "origin/$branch" ]] || fail "remote worktree has wrong upstream"
  rm -rf "$root"
}

test_remote_branch_uses_existing_correct_tracking_branch() {
  local root repo branch worktree remote_commit
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/remote-existing
  worktree="$root/desk-tools-feature-remote-existing"
  create_remote_branch "$repo" "$branch"
  remote_commit=$(git -C "$repo" rev-parse "refs/remotes/origin/$branch")
  git -C "$repo" branch --track "$branch" "origin/$branch" >/dev/null

  create_remote_worktree "$repo" "$branch"

  assert_exists "$worktree"
  [[ "$(git -C "$worktree" rev-parse HEAD)" == "$remote_commit" ]] || fail "existing tracking branch has wrong commit"
  [[ "$(git -C "$worktree" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')" == "origin/$branch" ]] || fail "existing tracking branch has wrong upstream"
  rm -rf "$root"
}

test_remote_branch_fast_forwards_behind_tracking_branch() {
  local root repo branch worktree remote_commit
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/remote-behind
  worktree="$root/desk-tools-feature-remote-behind"
  create_remote_branch "$repo" "$branch"
  git -C "$repo" branch --track "$branch" "origin/$branch" >/dev/null
  advance_remote_branch "$repo" "$branch" "remote advance"
  remote_commit=$(git -C "$repo" rev-parse "origin/$branch")

  create_remote_worktree "$repo" "$branch"

  [[ "$(git -C "$worktree" rev-parse HEAD)" == "$remote_commit" ]] || fail "behind tracking branch was not fast-forwarded"
  rm -rf "$root"
}

test_remote_branch_preserves_ahead_tracking_branch() {
  local root repo branch worktree local_commit
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/remote-ahead
  worktree="$root/desk-tools-feature-remote-ahead"
  create_remote_branch "$repo" "$branch"
  git -C "$repo" branch --track "$branch" "origin/$branch" >/dev/null
  git -C "$repo" switch "$branch" >/dev/null
  printf 'local advance\n' >"$repo/local-update.txt"
  git -C "$repo" add local-update.txt
  git -C "$repo" commit -m "advance local branch" >/dev/null
  local_commit=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" switch main >/dev/null

  create_remote_worktree "$repo" "$branch"

  [[ "$(git -C "$worktree" rev-parse HEAD)" == "$local_commit" ]] || fail "ahead tracking branch lost local commits"
  rm -rf "$root"
}

test_remote_branch_refuses_diverged_tracking_branch() {
  local root repo branch worktree local_commit
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/remote-diverged
  worktree="$root/desk-tools-feature-remote-diverged"
  create_remote_branch "$repo" "$branch"
  git -C "$repo" branch --track "$branch" "origin/$branch" >/dev/null
  git -C "$repo" switch "$branch" >/dev/null
  printf 'local advance\n' >"$repo/local-update.txt"
  git -C "$repo" add local-update.txt
  git -C "$repo" commit -m "advance local branch" >/dev/null
  local_commit=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" switch main >/dev/null
  advance_remote_branch "$repo" "$branch" "different remote advance"

  if create_remote_worktree "$repo" "$branch"; then
    fail "remote worktree unexpectedly accepted a diverged tracking branch"
  fi

  assert_missing "$worktree"
  [[ "$(git -C "$repo" rev-parse "$branch")" == "$local_commit" ]] || fail "diverged local branch changed after refusal"
  rm -rf "$root"
}

test_remote_branch_refuses_missing_upstream() {
  local root repo branch worktree branch_commit
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/no-upstream
  worktree="$root/desk-tools-feature-no-upstream"
  create_remote_branch "$repo" "$branch"
  git -C "$repo" branch --no-track "$branch" "origin/$branch"
  branch_commit=$(git -C "$repo" rev-parse "$branch")

  if create_remote_worktree "$repo" "$branch"; then
    fail "remote worktree unexpectedly accepted a local branch without an upstream"
  fi

  assert_missing "$worktree"
  assert_branch_exists "$repo" "$branch"
  [[ "$(git -C "$repo" rev-parse "$branch")" == "$branch_commit" ]] || fail "branch changed after missing-upstream refusal"
  if git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name "$branch@{upstream}" >/dev/null 2>&1; then
    fail "missing upstream was added during refusal"
  fi
  rm -rf "$root"
}

test_remote_branch_refuses_mismatched_upstream() {
  local root repo branch worktree branch_commit
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/wrong-upstream
  worktree="$root/desk-tools-feature-wrong-upstream"
  create_remote_branch "$repo" "$branch"
  git -C "$repo" branch --track "$branch" "origin/$branch" >/dev/null
  git -C "$repo" branch --set-upstream-to=origin/main "$branch" >/dev/null
  branch_commit=$(git -C "$repo" rev-parse "$branch")

  if create_remote_worktree "$repo" "$branch"; then
    fail "remote worktree unexpectedly accepted a mismatched upstream"
  fi

  assert_missing "$worktree"
  assert_branch_exists "$repo" "$branch"
  [[ "$(git -C "$repo" rev-parse "$branch")" == "$branch_commit" ]] || fail "branch changed after mismatched-upstream refusal"
  [[ "$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name "$branch@{upstream}")" == "origin/main" ]] || fail "upstream changed after refusal"
  rm -rf "$root"
}

test_path_naming_and_clean_creation() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch="$USER/feature/test-worktree"
  worktree="$root/desk-tools-feature-test-worktree"

  create_feature_worktree "$repo" "$branch"
  assert_exists "$worktree"
  [[ "$(git -C "$worktree" branch --show-current)" == "$branch" ]] || fail "wrong branch in worktree"
  [[ -z "$(git -C "$worktree" status --porcelain)" ]] || fail "new worktree is dirty"
  rm -rf "$root"
}

test_dirty_cleanup_is_refused() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/dirty
  worktree="$root/desk-tools-feature-dirty"
  create_feature_worktree "$repo" "$branch"
  create_session_files "$worktree"
  printf 'dirty\n' >"$worktree/dirty.txt"

  if (
    cd "$repo"
    printf 'n\n' | "$CLEANUP_WORKTREE" "$worktree" "$branch"
  ); then
    fail "dirty cleanup unexpectedly succeeded"
  fi
  assert_exists "$worktree"
  assert_branch_exists "$repo" "$branch"
  assert_exists "$(current_session_file "$worktree")"
  assert_exists "$(legacy_session_file "$worktree")"
  rm -rf "$root"
}

test_ignored_files_cleanup_is_refused() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/ignored
  worktree="$root/desk-tools-feature-ignored"
  create_feature_worktree "$repo" "$branch"
  printf '.env\n' >>"$(git -C "$repo" rev-parse --git-common-dir)/info/exclude"
  printf 'secret\n' >"$worktree/.env"

  if (
    cd "$repo"
    printf 'n\n' | "$CLEANUP_WORKTREE" "$worktree" "$branch"
  ); then
    fail "cleanup unexpectedly deleted an ignored file"
  fi

  assert_exists "$worktree/.env"
  assert_branch_exists "$repo" "$branch"
  rm -rf "$root"
}

test_confirmed_dirty_cleanup_is_deleted() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/confirmed-dirty
  worktree="$root/desk-tools-feature-confirmed-dirty"
  create_feature_worktree "$repo" "$branch"
  printf '.env\n' >>"$(git -C "$repo" rev-parse --git-common-dir)/info/exclude"
  printf 'untracked\n' >"$worktree/untracked.txt"
  printf 'ignored\n' >"$worktree/.env"

  (
    cd "$repo"
    LAZYGIT_CLEANUP_CONFIRMED=1 "$CLEANUP_WORKTREE" "$branch" </dev/null
  )

  assert_missing "$worktree"
  assert_branch_missing "$repo" "$branch"
  rm -rf "$root"
}

test_current_worktree_cleanup_is_refused() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/current
  worktree="$root/desk-tools-feature-current"
  create_feature_worktree "$repo" "$branch"

  if (
    cd "$worktree"
    "$CLEANUP_WORKTREE" "$worktree" "$branch"
  ); then
    fail "cleanup unexpectedly removed the current worktree"
  fi

  assert_exists "$worktree"
  assert_branch_exists "$repo" "$branch"
  rm -rf "$root"
}

test_cleanup_resolves_worktree_from_branch() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/from-local-branches
  worktree="$root/desk-tools-feature-from-local-branches"
  create_feature_worktree "$repo" "$branch"

  (
    cd "$repo"
    "$CLEANUP_WORKTREE" "$branch" </dev/null
  )

  assert_missing "$worktree"
  assert_branch_missing "$repo" "$branch"
  rm -rf "$root"
}

test_pushed_branch_is_deleted_without_confirmation() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/pushed
  worktree="$root/desk-tools-feature-pushed"
  create_feature_worktree "$repo" "$branch"
  printf 'pushed\n' >"$worktree/pushed.txt"
  git -C "$worktree" add pushed.txt
  git -C "$worktree" commit -m pushed >/dev/null
  git -C "$worktree" push -u origin "$branch" >/dev/null

  (
    cd "$repo"
    "$CLEANUP_WORKTREE" "$worktree" "$branch" </dev/null
  )
  assert_missing "$worktree"
  assert_branch_missing "$repo" "$branch"
  git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$branch" || fail "remote branch was removed"
  rm -rf "$root"
}

test_pushed_branch_without_upstream_is_deleted_without_confirmation() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/pushed-without-upstream
  worktree="$root/desk-tools-feature-pushed-without-upstream"
  create_feature_worktree "$repo" "$branch"
  printf 'pushed\n' >"$worktree/pushed.txt"
  git -C "$worktree" add pushed.txt
  git -C "$worktree" commit -m pushed >/dev/null
  git -C "$worktree" push origin "$branch" >/dev/null

  if git -C "$worktree" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
    fail "test branch unexpectedly has an upstream"
  fi

  (
    cd "$repo"
    "$CLEANUP_WORKTREE" "$worktree" "$branch" </dev/null
  )
  assert_missing "$worktree"
  assert_branch_missing "$repo" "$branch"
  git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$branch" || fail "remote branch was removed"
  rm -rf "$root"
}

test_merged_branch_is_deleted_without_confirmation() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/merged
  worktree="$root/desk-tools-feature-merged"
  create_feature_worktree "$repo" "$branch"
  printf 'merged\n' >"$worktree/merged.txt"
  git -C "$worktree" add merged.txt
  git -C "$worktree" commit -m merged >/dev/null
  git -C "$repo" merge --ff-only "$branch" >/dev/null

  (
    cd "$repo"
    "$CLEANUP_WORKTREE" "$worktree" "$branch" </dev/null
  )
  assert_missing "$worktree"
  assert_branch_missing "$repo" "$branch"
  rm -rf "$root"
}

test_unpushed_branch_requires_confirmation() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/unmerged
  worktree="$root/desk-tools-feature-unmerged"
  create_feature_worktree "$repo" "$branch"
  printf 'unmerged\n' >"$worktree/unmerged.txt"
  git -C "$worktree" add unmerged.txt
  git -C "$worktree" commit -m unmerged >/dev/null
  create_session_files "$worktree"

  if (
    cd "$repo"
    printf 'n\n' | "$CLEANUP_WORKTREE" "$worktree" "$branch"
  ); then
    fail "unmerged cleanup unexpectedly succeeded without confirmation"
  fi
  assert_exists "$worktree"
  assert_branch_exists "$repo" "$branch"
  assert_exists "$(current_session_file "$worktree")"
  assert_exists "$(legacy_session_file "$worktree")"
  rm -rf "$root"
}

test_confirmed_unpushed_branch_is_deleted() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/confirmed
  worktree="$root/desk-tools-feature-confirmed"
  create_feature_worktree "$repo" "$branch"
  printf 'confirmed\n' >"$worktree/confirmed.txt"
  git -C "$worktree" add confirmed.txt
  git -C "$worktree" commit -m confirmed >/dev/null
  create_session_files "$worktree"

  (
    cd "$repo"
    printf 'y\n' | "$CLEANUP_WORKTREE" "$worktree" "$branch"
  )
  assert_missing "$worktree"
  assert_branch_missing "$repo" "$branch"
  assert_missing "$(current_session_file "$worktree")"
  assert_missing "$(legacy_session_file "$worktree")"
  rm -rf "$root"
}

test_lazygit_confirmation_deletes_unpushed_branch_without_terminal_input() {
  local root repo branch worktree
  root=$(new_test_root)
  repo=$(new_repository "$root")
  branch=feature/lazygit-confirmed
  worktree="$root/desk-tools-feature-lazygit-confirmed"
  create_feature_worktree "$repo" "$branch"
  printf 'confirmed\n' >"$worktree/confirmed.txt"
  git -C "$worktree" add confirmed.txt
  git -C "$worktree" commit -m confirmed >/dev/null

  (
    cd "$repo"
    LAZYGIT_CLEANUP_CONFIRMED=1 "$CLEANUP_WORKTREE" "$branch" </dev/null
  )

  assert_missing "$worktree"
  assert_branch_missing "$repo" "$branch"
  rm -rf "$root"
}

main() {
  TEST_STATE_ROOT=$(mktemp -d "/tmp/lazygit home.XXXXXX")
  export XDG_DATA_HOME="$TEST_STATE_ROOT/.local/share"
  trap 'rm -rf "$TEST_STATE_ROOT"' EXIT
  test_new_branch_uses_selected_base
  test_remote_branch_creates_tracking_worktree
  test_remote_branch_uses_existing_correct_tracking_branch
  test_remote_branch_fast_forwards_behind_tracking_branch
  test_remote_branch_preserves_ahead_tracking_branch
  test_remote_branch_refuses_diverged_tracking_branch
  test_remote_branch_refuses_missing_upstream
  test_remote_branch_refuses_mismatched_upstream
  test_path_naming_and_clean_creation
  test_dirty_cleanup_is_refused
  test_ignored_files_cleanup_is_refused
  test_confirmed_dirty_cleanup_is_deleted
  test_current_worktree_cleanup_is_refused
  test_cleanup_resolves_worktree_from_branch
  test_pushed_branch_is_deleted_without_confirmation
  test_pushed_branch_without_upstream_is_deleted_without_confirmation
  test_merged_branch_is_deleted_without_confirmation
  test_unpushed_branch_requires_confirmation
  test_confirmed_unpushed_branch_is_deleted
  test_lazygit_confirmation_deletes_unpushed_branch_without_terminal_input
  printf 'PASS: worktree lifecycle tests\n'
}

main "$@"
