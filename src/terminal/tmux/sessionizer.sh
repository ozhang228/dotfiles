#!/usr/bin/env bash
# Navigate from a project to one of its Git worktrees and its tmux session.
#
# - The first picker contains one entry per project.
# - The second picker contains every registered worktree, including stale ones.
# - Entries are sorted by most-recently-active tmux session first.
# - ctrl-x only removes the highlighted stale worktree registration.
set -euo pipefail

SCRIPT=$(realpath "$0")
printf -v SCRIPT_Q '%q' "$SCRIPT"

collect_candidates() {
    candidates=()
    local root dir

    for root in ~/forge ~/dotfiles ~/blog ~/anvil; do
        [ -d "$root" ] && candidates+=("$root")
    done

    if [ -d ~/drw ]; then
        for dir in ~/drw/*/; do
            [ -d "$dir" ] && candidates+=("${dir%/}")
        done
    fi
}

load_session_activity() {
    declare -gA session_activity
    session_activity=()

    while IFS='|' read -r name timestamp; do
        [ -n "$name" ] && session_activity["$name"]="$timestamp"
    done < <(tmux list-sessions -F '#{session_name}|#{session_activity}' 2>/dev/null || true)
}

session_name_for_path() {
    basename "$1" | tr '.:' '__'
}

git_common_dir_for() {
    git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null
}

ai_status_icons() {
    local session="$1"
    local pane_dir="$HOME/.cache/tmux-ai-status/panes"
    [ -d "$pane_dir" ] || return 0

    local active_panes icons=() f pane_id
    active_panes=$(tmux list-panes -t "$session" -F '#{pane_id}' 2>/dev/null || true)
    for f in "$pane_dir/${session}_"*.status; do
        [ -f "$f" ] || continue
        pane_id=$(basename "$f" .status)
        pane_id="${pane_id#${session}_}"
        printf '%s\n' "$active_panes" | grep -qx "$pane_id" || continue
        case "$(cat "$f" 2>/dev/null)" in
            working) icons+=("⚡") ;;
            done)    icons+=("✅") ;;
            wait)    icons+=("⏸") ;;
        esac
    done

    [ "${#icons[@]}" -gt 0 ] && printf '%s' "${icons[*]}"
    return 0
}

# Emit: worktree path, branch/detached label, stale flag.
worktree_records() {
    local git_dir="$1"
    [ -n "$git_dir" ] || return 0

    local path="" branch="" stale=0 line
    flush_worktree_record() {
        [ -n "$path" ] || return 0
        [ -n "$branch" ] || branch="(detached)"
        [ -d "$path" ] || stale=1
        printf '%s\t%s\t%s\n' "$path" "$branch" "$stale"
        path=""
        branch=""
        stale=0
    }

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            worktree\ *)
                flush_worktree_record
                path="${line#worktree }"
                ;;
            branch\ *)
                branch="${line#branch }"
                branch="${branch#refs/heads/}"
                ;;
            detached)
                branch="(detached)"
                ;;
            prunable\ *)
                stale=1
                ;;
        esac
    done < <(git --git-dir="$git_dir" worktree list --porcelain 2>/dev/null || true)

    flush_worktree_record
}

project_list() {
    collect_candidates
    load_session_activity

    declare -A project_git_dirs
    local -a projects=() entries=()
    local dir git_dir project path branch stale session timestamp recent count label

    for dir in "${candidates[@]}"; do
        if git_dir=$(git_common_dir_for "$dir"); then
            if [[ "$git_dir" == */.git ]]; then
                project="${git_dir%/.git}"
            else
                project="$dir"
            fi
        else
            git_dir=""
            project="$dir"
        fi

        if [ -z "${project_git_dirs[$project]+x}" ]; then
            projects+=("$project")
            project_git_dirs["$project"]="$git_dir"
        fi
    done

    for project in "${projects[@]}"; do
        git_dir="${project_git_dirs[$project]}"
        recent=0
        count=0

        if [ -n "$git_dir" ]; then
            while IFS=$'\t' read -r path branch stale; do
                [ -n "$path" ] || continue
                count=$((count + 1))
                session=$(session_name_for_path "$path")
                timestamp="${session_activity[$session]:-0}"
                if [ "$timestamp" -gt "$recent" ]; then
                    recent="$timestamp"
                fi
            done < <(worktree_records "$git_dir")
        else
            count=1
            session=$(session_name_for_path "$project")
            recent="${session_activity[$session]:-0}"
        fi

        label="$(basename "$project")  ·  $count worktrees"
        entries+=("$recent"$'\t'"$project"$'\t'"$count"$'\t'"$label")
    done

    printf '%s\n' "${entries[@]}" \
        | sort -t $'\t' -k1,1rn -k4,4 \
        | cut -f1-4
}

worktree_list() {
    local project="$1" git_dir path branch stale session timestamp ai_status label
    local -a entries=()
    load_session_activity

    if git_dir=$(git_common_dir_for "$project"); then
        while IFS=$'\t' read -r path branch stale; do
            [ -n "$path" ] || continue
            session=$(session_name_for_path "$path")
            timestamp="${session_activity[$session]:-0}"
            label="$branch  ·  $path"

            if [ "$stale" -eq 1 ]; then
                label="🗑 stale  ·  $label"
            elif [ -n "${session_activity[$session]+x}" ]; then
                label="$label  ·  ●"
                ai_status=$(ai_status_icons "$session")
                [ -n "$ai_status" ] && label="$label $ai_status"
            fi

            entries+=("$timestamp"$'\t'"$path"$'\t'"$branch"$'\t'"$label"$'\t'"$stale")
        done < <(worktree_records "$git_dir")
    else
        session=$(session_name_for_path "$project")
        timestamp="${session_activity[$session]:-0}"
        label="directory  ·  $project"
        if [ -n "${session_activity[$session]+x}" ]; then
            label="$label  ·  ●"
        fi
        entries+=("$timestamp"$'\t'"$project"$'\t'directory$'\t'"$label"$'\t'0)
    fi

    printf '%s\n' "${entries[@]}" \
        | sort -t $'\t' -k5,5rn -k1,1rn -k3,3 -k2,2 \
        | cut -f1-4
}

preview_project() {
    local project="$1" git_dir
    ls -la --color=always -- "$project" 2>/dev/null || true
    if git_dir=$(git_common_dir_for "$project"); then
        echo
        git --git-dir="$git_dir" worktree list 2>/dev/null || true
    fi
}

preview_worktree() {
    local project="$1" path="$2"
    if [ ! -d "$path" ]; then
        printf '🗑 stale worktree: %s\n' "$path"
        return 0
    fi

    ls -la --color=always -- "$path" 2>/dev/null || true
    if git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo
        git -C "$path" log --oneline --color=always -10 2>/dev/null || true
    fi
}

prune_stale_worktree() {
    local project="$1" selected_path="$2" git_dir path branch stale
    local found=0 selected_stale=0
    git_dir=$(git_common_dir_for "$project" 2>/dev/null) || return 0

    while IFS=$'\t' read -r path branch stale; do
        if [ "$path" = "$selected_path" ]; then
            found=1
            selected_stale="$stale"
            break
        fi
    done < <(worktree_records "$git_dir")

    [ "$found" -eq 1 ] || return 0
    [ "$selected_stale" -eq 1 ] || return 0
    [ ! -e "$selected_path" ] && [ ! -L "$selected_path" ] || return 0

    git --git-dir="$git_dir" worktree remove --force -- "$selected_path" >/dev/null 2>&1 || true
}

open_worktree() {
    local path="$1" session_name
    session_name=$(session_name_for_path "$path")
    if ! tmux has-session -t "=$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$path"
    fi

    if [ -n "${TMUX:-}" ]; then
        if [ -n "${TMUX_SESSIONIZER_CLIENT:-}" ]; then
            tmux switch-client -c "$TMUX_SESSIONIZER_CLIENT" -t "=$session_name"
        else
            tmux switch-client -t "=$session_name"
        fi
    else
        tmux attach-session -t "=$session_name"
    fi
}

run_worktree_picker() {
    local project="$1" project_q selected path fzf_status
    printf -v project_q '%q' "$project"

    while true; do
        fzf_status=0
        selected=$(worktree_list "$project" | fzf \
            --border=none \
            --delimiter $'\t' --with-nth=4 \
            --tiebreak=index \
            --header='Enter: switch/create  |  ctrl-x: remove stale  |  Esc: projects' \
            --bind "ctrl-x:execute-silent($SCRIPT_Q --prune-worktree $project_q {2})+reload($SCRIPT_Q --worktrees $project_q)" \
            --info=hidden \
            --preview "$SCRIPT_Q --preview-worktree $project_q {2}" \
            --preview-window right:60%,nowrap,noinfo,border-left) || fzf_status=$?

        case "$fzf_status" in
            0) ;;
            1|130) return 1 ;;
            *) return "$fzf_status" ;;
        esac

        [ -n "$selected" ] || return 1
        path=$(printf '%s' "$selected" | cut -f2)
        if [ -d "$path" ]; then
            open_worktree "$path"
            return 0
        fi
    done
}

run_project_picker() {
    local selected project fzf_status worktree_status

    while true; do
        fzf_status=0
        selected=$(project_list | fzf \
            --border=none \
            --delimiter $'\t' --with-nth=4 \
            --tiebreak=index \
            --header='Enter: choose project  |  Esc: exit' \
            --info=hidden \
            --preview "$SCRIPT_Q --preview-project {2}" \
            --preview-window right:60%,nowrap,noinfo,border-left) || fzf_status=$?

        case "$fzf_status" in
            0) ;;
            1|130) return 0 ;;
            *) return "$fzf_status" ;;
        esac

        [ -n "$selected" ] || return 0
        project=$(printf '%s' "$selected" | cut -f2)
        worktree_status=0
        run_worktree_picker "$project" || worktree_status=$?
        case "$worktree_status" in
            0) return 0 ;;
            1) ;;
            *) return "$worktree_status" ;;
        esac
    done
}

case "${1:-}" in
    --list)
        project_list
        ;;
    --worktrees)
        [ "$#" -ge 2 ] && worktree_list "$2"
        ;;
    --preview-project)
        [ "$#" -ge 2 ] && preview_project "$2"
        ;;
    --preview-worktree)
        [ "$#" -ge 3 ] && preview_worktree "$2" "$3"
        ;;
    --prune-worktree)
        [ "$#" -ge 3 ] && prune_stale_worktree "$2" "$3"
        ;;
    *)
        run_project_picker
        ;;
esac
