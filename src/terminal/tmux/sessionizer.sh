#!/usr/bin/env bash
# Fuzzy-pick a project, worktree, or existing tmux session.
#
# - Worktrees are labeled by their filesystem directory name in one flat list.
# - Existing sessions, including standalone sessions such as "default", remain visible.
# - Stale worktrees sort first and ctrl-x only removes the highlighted stale registration.
# - All entries are ordered by stale status, then most-recently-active session.
set -euo pipefail

SCRIPT=$(realpath "$0")
printf -v SCRIPT_Q '%q' "$SCRIPT"
REPLY=""

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
    declare -gA session_activity session_paths
    session_activity=()
    session_paths=()

    while IFS='|' read -r name timestamp path; do
        [ -n "$name" ] || continue
        session_activity["$name"]="$timestamp"
        session_paths["$name"]="$path"
    done < <(tmux list-sessions -F '#{session_name}|#{session_activity}|#{session_path}' 2>/dev/null || true)

    load_ai_statuses
}

path_basename() {
    local path="$1"
    path="${path%/}"
    REPLY="${path##*/}"
}

session_name_for_path() {
    local name
    path_basename "$1"
    name="$REPLY"
    name="${name//./_}"
    name="${name//:/_}"
    REPLY="$name"
}

git_common_dir_from_marker() {
    local path="$1" marker="$1/.git" git_dir

    if [ -d "$marker" ]; then
        printf '%s' "$marker"
        return 0
    fi

    [ -f "$marker" ] || return 1
    IFS= read -r git_dir < "$marker" || return 1
    case "$git_dir" in
        "gitdir: "/*/.git/worktrees/*)
            git_dir="${git_dir#gitdir: }"
            printf '%s' "${git_dir%%/worktrees/*}"
            ;;
        *)
            return 1
            ;;
    esac
}

git_common_dir_for() {
    git_common_dir_from_marker "$1" || \
        git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null
}

load_ai_statuses() {
    local pane_dir="$HOME/.cache/tmux-ai-status/panes"
    declare -gA session_ai_statuses
    session_ai_statuses=()
    [ -d "$pane_dir" ] || return 0

    declare -A active_panes=()
    local session pane key f filename stem pane_id status icon
    while IFS='|' read -r session pane; do
        [ -n "$session" ] || continue
        key="$session|$pane"
        active_panes["$key"]=1
    done < <(tmux list-panes -a -F '#{session_name}|#{pane_id}' 2>/dev/null || true)

    for f in "$pane_dir"/*.status; do
        [ -f "$f" ] || continue
        filename="${f##*/}"
        stem="${filename%.status}"
        pane_id="${stem##*_}"
        session="${stem%_$pane_id}"
        key="$session|$pane_id"
        [ -n "${active_panes[$key]+x}" ] || continue
        IFS= read -r status < "$f" || status=""
        case "$status" in
            working) icon="⚡" ;;
            done)    icon="✅" ;;
            wait)    icon="⏸" ;;
            *)       icon="" ;;
        esac
        [ -n "$icon" ] || continue
        if [ -n "${session_ai_statuses[$session]+x}" ]; then
            session_ai_statuses["$session"]+=" $icon"
        else
            session_ai_statuses["$session"]="$icon"
        fi
    done
}

ai_status_icons() {
    REPLY="${session_ai_statuses[$1]:-}"
}

session_indicator() {
    local session="$1"
    if [ -n "${session_activity[$session]+x}" ]; then
        REPLY=$'\033[92m•\033[0m'
    else
        REPLY=$'\033[90m○\033[0m'
    fi
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

collect_projects() {
    collect_candidates
    declare -gA project_git_dirs
    declare -ga projects
    project_git_dirs=()
    projects=()

    local dir git_dir project
    for dir in "${candidates[@]}"; do
        if git_dir=$(git_common_dir_from_marker "$dir"); then
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
}

build_worktree_index() {
    collect_projects
    declare -gA worktree_branches worktree_stale worktree_projects
    worktree_branches=()
    worktree_stale=()
    worktree_projects=()

    local -a indexed_records=()
    local project git_dir path branch stale record

    # Git worktree reads are independent. Run them concurrently so one slow
    # repository does not make every fzf reload wait behind others.
    mapfile -t indexed_records < <(
        for project in "${projects[@]}"; do
            git_dir="${project_git_dirs[$project]}"
            if [ -n "$git_dir" ]; then
                worktree_records "$git_dir" \
                    | while IFS=$'\t' read -r path branch stale; do
                        [ -n "$path" ] || continue
                        printf '%s\t%s\t%s\t%s\n' \
                            "$project" "$path" "$branch" "$stale"
                    done &
            else
                printf '%s\t%s\tdirectory\t0\n' "$project" "$project"
            fi
        done
        wait
    )

    for record in "${indexed_records[@]}"; do
        IFS=$'\t' read -r project path branch stale <<<"$record"
        [ -n "$path" ] || continue
        worktree_branches["$path"]="$branch"
        worktree_stale["$path"]="$stale"
        worktree_projects["$path"]="$project"
    done
}

worktree_label() {
    local path="$1" stale="$2" label
    path_basename "$path"
    label="$REPLY"

    [ "$stale" -eq 1 ] && label="🗑 stale  $label"
    REPLY="$label"
}

label_session() {
    local label="$1" session="$2" ai_status indicator
    session_indicator "$session"
    indicator="$REPLY"
    label="$label $indicator"
    ai_status_icons "$session"
    ai_status="$REPLY"
    [ -n "$ai_status" ] && label="$label $ai_status"
    REPLY="$label"
}

list_entries() {
    load_session_activity
    build_worktree_index

    local -a entries=()
    declare -A project_recent=()
    local name path project branch stale session timestamp label git_dir kind indicator
    local group_timestamp index

    # Keep every existing tmux session, even when it is not a discovered project.
    for name in "${!session_activity[@]}"; do
        path="${session_paths[$name]}"
        project="${worktree_projects[$path]:-}"
        branch="${worktree_branches[$path]:-}"

        if [ -z "$project" ] && [ -d "$path" ] && git_dir=$(git_common_dir_for "$path"); then
            if [[ "$git_dir" == */.git ]]; then
                project="${git_dir%/.git}"
                branch=$(git -C "$path" branch --show-current 2>/dev/null || true)
                [ -n "$branch" ] || branch="(detached)"
            fi
        fi

        if [ -n "$project" ] && [ -n "$branch" ]; then
            worktree_label "$path" 0
            label="$REPLY"
        else
            label="$name"
            project="-"
        fi
        label_session "$label" "$name"
        label="$REPLY"
        timestamp="${session_activity[$name]:-0}"
        if [ "$timestamp" -gt "${project_recent[$project]:-0}" ]; then
            project_recent["$project"]="$timestamp"
        fi
        entries+=("0"$'\t'"$timestamp"$'\t'session$'\t'"$name"$'\t'"$label"$'\t'"$project")
    done

    # Add every discovered worktree that does not already have a live session.
    for path in "${!worktree_projects[@]}"; do
        project="${worktree_projects[$path]}"
        branch="${worktree_branches[$path]}"
        stale="${worktree_stale[$path]}"
        session_name_for_path "$path"
        session="$REPLY"
        if [ "$stale" -eq 0 ] && [ -n "${session_activity[$session]+x}" ]; then
            continue
        fi

        timestamp="${session_activity[$session]:-0}"
        worktree_label "$path" "$stale"
        label="$REPLY"
        session_indicator "$session"
        indicator="$REPLY"
        label="$label $indicator"
        if [ "$branch" = "directory" ]; then
            kind=directory
        else
            kind=worktree
        fi
        if [ "$timestamp" -gt "${project_recent[$project]:-0}" ]; then
            project_recent["$project"]="$timestamp"
        fi
        entries+=("$stale"$'\t'"$timestamp"$'\t'"$kind"$'\t'"$path"$'\t'"$label"$'\t'"$project")
    done

    # Keep the most recently used project groups first, then sort each group
    # by its stable filesystem name so the project root precedes its worktrees.
    for index in "${!entries[@]}"; do
        IFS=$'\t' read -r stale timestamp kind path label project <<<"${entries[$index]}"
        group_timestamp="${project_recent[$project]:-0}"
        entries[$index]="$stale"$'\t'"$group_timestamp"$'\t'"$timestamp"$'\t'"$kind"$'\t'"$path"$'\t'"$label"$'\t'"$project"
    done

    printf '%s\n' "${entries[@]}" \
        | sort -t $'\t' -k1,1rn -k2,2rn -k6,6 -k3,3rn \
        | cut -f1,3-7
}

preview_entry() {
    local kind="$1" key="$2"
    if [ "$kind" = "session" ]; then
        tmux capture-pane -e -p -t "$key" 2>/dev/null || true
        return 0
    fi

    if [ ! -d "$key" ]; then
        printf '🗑 stale worktree: %s\n' "$key"
        return 0
    fi

    ls -la --color=always -- "$key" 2>/dev/null || true
    if git -C "$key" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo
        git -C "$key" log --oneline --color=always -10 2>/dev/null || true
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

open_session() {
    local session="$1"
    if [ -n "${TMUX:-}" ]; then
        if [ -n "${TMUX_SESSIONIZER_CLIENT:-}" ]; then
            tmux switch-client -c "$TMUX_SESSIONIZER_CLIENT" -t "=$session"
        else
            tmux switch-client -t "=$session"
        fi
    else
        tmux attach-session -t "=$session"
    fi
}

open_worktree() {
    local path="$1" session
    session_name_for_path "$path"
    session="$REPLY"
    if ! tmux has-session -t "=$session" 2>/dev/null; then
        tmux new-session -d -s "$session" -c "$path"
    fi
    open_session "$session"
}

client_size() {
    tmux display-message -p -t "$1" '#{client_width}x#{client_height}' 2>/dev/null
}

open_popup() {
    local client="$1"
    tmux display-popup \
        -c "$client" \
        -w 100% \
        -h 100% \
        -e "TMUX_SESSIONIZER_CLIENT=$client" \
        -E "$SCRIPT_Q"
}

run_resizing_popup() {
    local client="$1" popup_pid size new_size pending_size pending_checks

    open_popup "$client" &
    popup_pid=$!
    size=$(client_size "$client") || size=""
    pending_size=""
    pending_checks=0

    while kill -0 "$popup_pid" 2>/dev/null; do
        sleep 0.1
        new_size=$(client_size "$client") || break
        if [ -z "$new_size" ] || [ "$new_size" = "$size" ]; then
            pending_size=""
            pending_checks=0
            continue
        fi

        if [ "$new_size" != "$pending_size" ]; then
            pending_size="$new_size"
            pending_checks=1
            continue
        fi

        pending_checks=$((pending_checks + 1))
        if [ "$pending_checks" -ge 2 ]; then
            tmux display-popup -C -c "$client" 2>/dev/null || true
            wait "$popup_pid" 2>/dev/null || true
            open_popup "$client" &
            popup_pid=$!
            size="$new_size"
            pending_size=""
            pending_checks=0
        fi
    done

    wait "$popup_pid" 2>/dev/null || true
}

case "${1:-}" in
    --list)
        list_entries
        exit 0
        ;;
    --preview)
        [ "$#" -ge 3 ] && preview_entry "$2" "$3"
        exit 0
        ;;
    --prune-worktree)
        [ "$#" -ge 3 ] && prune_stale_worktree "$2" "$3"
        exit 0
        ;;
    --popup)
        [ "$#" -ge 2 ] || exit 2
        run_resizing_popup "$2"
        exit 0
        ;;
esac

fzf_status=0
selected=""
while true; do
    selected=$(list_entries | fzf \
        --border=none \
        --ansi \
        --delimiter $'\t' --with-nth=5 \
        --tiebreak=index \
        --header='Enter: switch/create live  |  ctrl-x: remove stale  |  Esc: exit' \
        --bind "ctrl-x:execute-silent($SCRIPT_Q --prune-worktree {6} {4})+reload($SCRIPT_Q --list)" \
        --info=hidden \
        --preview "$SCRIPT_Q --preview {3} {4} {6}" \
        --preview-window right:60%,nowrap,noinfo,border-left) || fzf_status=$?

    case "$fzf_status" in
        0) ;;
        1|130) exit 0 ;;
        *) exit "$fzf_status" ;;
    esac

    [ -n "$selected" ] || exit 0
    stale=$(printf '%s' "$selected" | cut -f1)
    kind=$(printf '%s' "$selected" | cut -f3)
    key=$(printf '%s' "$selected" | cut -f4)

    # Selecting a stale row does not attempt to create a session.
    [ "$stale" -eq 0 ] || continue
    if [ "$kind" = "session" ]; then
        open_session "$key"
    else
        [ -d "$key" ] && open_worktree "$key"
    fi
    exit 0
done
