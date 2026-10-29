#!/usr/bin/env bash
# Session picker for prefix f.
#
# - Live sessions by last attach (the current one last), then root worktrees
#   without a session, then stale worktree registrations.
# - Sessions are only created from the fixed roots, or by name with ctrl-n in
#   $TMUX_NEW_SESSION_DIR (default ~).
set -euo pipefail

SCRIPT=$(realpath "$0")
printf -v SCRIPT_Q '%q' "$SCRIPT"
REPLY=""

LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/sessionizer.log"
PROMPT='  '
CONFIRM_PREFIX='  kill '

# Catppuccin Macchiato.
GREEN=$'\e[38;2;166;218;149m' RED=$'\e[38;2;237;135;150m'
OVERLAY=$'\e[38;2;110;115;141m' BLUE=$'\e[38;2;138;173;244m' SUBTEXT=$'\e[38;2;165;173;203m' RESET=$'\e[0m'

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

current_session() {
    if [ -n "${TMUX_SESSIONIZER_CLIENT:-}" ]; then
        tmux display-message -p -c "$TMUX_SESSIONIZER_CLIENT" '#{client_session}' 2>/dev/null || true
    else
        tmux display-message -p '#{client_session}' 2>/dev/null || true
    fi
}

# Live sessions as "name<TAB>path<TAB>last attached", most recent first, current last.
live_sessions() {
    local current
    current=$(current_session)
    tmux list-sessions -F '#{session_last_attached}	#{session_name}	#{session_path}' 2>/dev/null \
        | sort -t $'\t' -k1,1rn \
        | awk -F '\t' -v current="$current" -v OFS='\t' '
            $2 == current { last = $2 OFS $3 OFS $1; next }
            { print $2, $3, $1 }
            END { if (last != "") print last }'
}

relative_age() {
    local attached="${1:-0}" seconds
    [ -n "$attached" ] || attached=0
    seconds=$(( $(date +%s) - attached ))
    if [ "$attached" -eq 0 ]; then REPLY=""
    elif [ "$seconds" -lt 60 ]; then REPLY="now"
    elif [ "$seconds" -lt 3600 ]; then REPLY="$((seconds / 60))m"
    elif [ "$seconds" -lt 86400 ]; then REPLY="$((seconds / 3600))h"
    else REPLY="$((seconds / 86400))d"
    fi
}

short_path() {
    REPLY="${1/#$HOME/\~}"
}

# Emit one row: kind, session name, path, project, then the displayed label.
# The label puts the path and age flush right, sized to fzf's width.
emit_row() {
    local kind="$1" name="$2" path="$3" project="$4" age="$5" icon left right gap
    case "$kind" in
        session) icon="${GREEN}●${RESET}" ;;
        start) icon="${OVERLAY}○${RESET}" ;;
        stale) icon="${RED}✗${RESET}" ;;
    esac
    short_path "$path"

    left="● $name"
    printf -v right '%s  %3s' "$REPLY" "$age"
    # fzf reports 0 columns during its start event, so fall back to the popup width.
    local width=${FZF_COLUMNS:-0}
    [ "$width" -gt 0 ] || width=${SESSIONIZER_WIDTH:-100}
    gap=$(( width - 6 - ${#left} - ${#right} ))
    if [ "$gap" -lt 2 ]; then
        REPLY="…${REPLY:$(( 2 - gap + 1 ))}"
        printf -v right '%s  %3s' "$REPLY" "$age"
        gap=2
    fi
    printf '%s\t%s\t%s\t%s\t%s %s%*s%s%s%s  %s%3s%s\n' \
        "$kind" "$name" "$path" "$project" \
        "$icon" "$name" "$gap" "" \
        "$OVERLAY" "$REPLY" "$RESET" "$SUBTEXT" "$age" "$RESET"
}

list_sessions() {
    local name path last_attached project branch stale
    declare -A live_paths=() live_names=()

    while IFS=$'\t' read -r name path last_attached; do
        live_names["$name"]=1
        live_paths["$path"]=1
        relative_age "$last_attached"
        emit_row session "$name" "$path" - "$REPLY"
    done < <(live_sessions)

    build_worktree_index
    local -a startable=() stale_rows=()
    for path in "${!worktree_projects[@]}"; do
        if [ "${worktree_stale[$path]}" -eq 1 ]; then
            stale_rows+=("$path")
            continue
        fi
        session_name_for_path "$path"
        [ -n "${live_paths[$path]+x}" ] || [ -n "${live_names[$REPLY]+x}" ] || startable+=("$path")
    done

    [ "${#startable[@]}" -eq 0 ] || while IFS= read -r path; do
        session_name_for_path "$path"
        emit_row start "$REPLY" "$path" "${worktree_projects[$path]}" ""
    done < <(printf '%s\n' "${startable[@]}" | awk -F / '{ print $NF "\t" $0 }' | sort | cut -f2-)

    for path in "${stale_rows[@]}"; do
        path_basename "$path"
        emit_row stale "$REPLY" "$path" "${worktree_projects[$path]}" ""
    done
}

open_entry() {
    local kind="$1" name="$2" path="$3"
    case "$kind" in
        session) open_session "$name" ;;
        start)
            tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$path"
            open_session "$name"
            ;;
        stale|"") ;;
    esac
}

new_session() {
    local name="$1" dir="${TMUX_NEW_SESSION_DIR:-$HOME}"
    [ -n "$name" ] || return 0
    session_name_for_path "$name"
    name="$REPLY"
    tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$dir"
    open_session "$name"
}

rename_session() {
    local kind="$1" name="$2" new_name="$3"
    [ "$kind" = session ] && [ -n "$new_name" ] || return 0
    session_name_for_path "$new_name"
    new_name="$REPLY"
    tmux has-session -t "=$new_name" 2>/dev/null && return 0
    tmux rename-session -t "=$name" "$new_name"
}

kill_entry() {
    local kind="$1" name="$2" path="$3" project="$4" fallback
    case "$kind" in
        session)
            if [ "$name" = "$(current_session)" ]; then
                fallback=$(live_sessions | cut -f1 | grep -Fvx -- "$name" | head -n1 || true)
                [ -z "$fallback" ] || open_session "$fallback"
            fi
            tmux kill-session -t "=$name"
            ;;
        stale) prune_stale_worktree "$project" "$path" ;;
        start|"") ;;
    esac
}

kill_all_stale() {
    local path
    build_worktree_index
    for path in "${!worktree_projects[@]}"; do
        [ "${worktree_stale[$path]}" -eq 1 ] && prune_stale_worktree "${worktree_projects[$path]}" "$path"
    done
    return 0
}

# Answer a y/n key: act on a pending kill confirmation, otherwise type the key.
answer_key() {
    local key="$1"
    case "${FZF_PROMPT:-}" in
        "$CONFIRM_PREFIX"*)
            if [ "$key" = y ]; then
                if [ "$FZF_PROMPT" = "${CONFIRM_PREFIX}all stale worktrees? y/n  " ]; then
                    printf 'execute-silent(%s --kill-all-stale)+' "$SCRIPT_Q"
                else
                    printf 'execute-silent(%s --kill {1} {2} {3} {4})+' "$SCRIPT_Q"
                fi
                printf 'reload(%s --list)+' "$SCRIPT_Q"
            fi
            printf 'change-prompt:%s' "$PROMPT"
            ;;
        *) [ "$key" = esc ] && printf 'abort' || printf 'put(%s)' "$key" ;;
    esac
}

confirm_kill() {
    case "$1" in
        session|stale) printf 'change-prompt:%s%s? y/n  ' "$CONFIRM_PREFIX" "$2" ;;
        *) ;;
    esac
}

# Size the popup to the list so short lists leave no empty space.
open_popup() {
    local client="$1" rows client_height client_width height width
    client_width=$(tmux display-message -p -c "$client" '#{client_width}')
    # 60% of the screen, but wide enough for the key hints in the footer.
    width=$(( client_width * 6 / 10 ))
    [ "$width" -ge 110 ] || width=110
    [ "$width" -le "$client_width" ] || width=$client_width
    rows=$("$SCRIPT" --list sessions 2>/dev/null | wc -l)
    client_height=$(tmux display-message -p -c "$client" '#{client_height}')
    # 8 rows of input, list, and footer borders.
    height=$(( rows + 8 ))
    [ "$height" -le $(( client_height * 8 / 10 )) ] || height=$(( client_height * 8 / 10 ))
    tmux display-popup -B -w "$width" -h "$height" -c "$client" \
        -e "TMUX_SESSIONIZER_CLIENT=$client" -e "SESSIONIZER_WIDTH=$width" \
        -E "$SCRIPT_Q"
}

# Format "key ➜ description" pairs like which-key.
key_hints() {
    local separator="$1" hint=""
    shift
    while [ "$#" -ge 2 ]; do
        hint+="${BLUE}$1${RESET} ${OVERLAY}➜${RESET} $2$separator"
        shift 2
    done
    REPLY="${hint%"$separator"}"
}

run_picker() {
    local footer

    key_hints '   ' '<CR>' open '<C-n>' 'new from query' '<C-r>' 'rename to query' '<C-x>' kill '<C-d>' 'kill all stale'
    footer=$REPLY

    # Ignore the shell's fzf defaults; their --height=90% draws inline and can cut off the top.
    FZF_DEFAULT_OPTS='' FZF_DEFAULT_OPTS_FILE='' fzf \
        --ansi --layout=reverse --style=full --border=none --gutter=' ' \
        --input-border=rounded --list-border=rounded --footer-border=rounded \
        --delimiter $'\t' --with-nth=5 --tiebreak=index \
        --input-label=' 󰆍 Sessions ' \
        --prompt="$PROMPT" --pointer='▌' \
        --info=inline-right --no-scrollbar \
        --footer="$footer" \
        --color='bg:#24273a,bg+:#363a4f,fg:#cad3f5,fg+:#cad3f5,hl:#ed8796,hl+:#ed8796' \
        --color='border:#b7bdf8,label:#cad3f5,prompt:#c6a0f6,pointer:#f4dbd6,info:#6e738d' \
        --color='header:#a5adcb,footer:#6e738d,query:#cad3f5,spinner:#f4dbd6,marker:#b7bdf8' \
        --bind "start:reload($SCRIPT_Q --list sessions)" \
        --bind "enter:become($SCRIPT_Q --open {1} {2} {3})" \
        --bind "ctrl-n:become($SCRIPT_Q --new {q})" \
        --bind "ctrl-r:execute-silent($SCRIPT_Q --rename {1} {2} {q})+clear-query+reload($SCRIPT_Q --list sessions)" \
        --bind "ctrl-x:transform($SCRIPT_Q --confirm-kill {1} {2})" \
        --bind "ctrl-d:change-prompt:${CONFIRM_PREFIX}all stale worktrees? y/n  " \
        --bind "y:transform($SCRIPT_Q --answer y),n:transform($SCRIPT_Q --answer n),esc:transform($SCRIPT_Q --answer esc)" \
        </dev/null || true
}

case "${1:-}" in
    --list)
        case "${2:-}" in
            sessions|"") list_sessions ;;
            *) printf 'unknown list: %s\n' "$2" >&2; exit 2 ;;
        esac
        ;;
    --open) open_entry "${2:-}" "${3:-}" "${4:-}" ;;
    --new) new_session "${2:-}" ;;
    --rename) rename_session "${2:-}" "${3:-}" "${4:-}" ;;
    --confirm-kill) confirm_kill "${2:-}" "${3:-}" ;;
    --answer) answer_key "$2" ;;
    --kill) kill_entry "${2:-}" "${3:-}" "${4:-}" "${5:-}" ;;
    --kill-all-stale) kill_all_stale ;;
    --popup)
        [ "$#" -ge 2 ] || exit 2
        open_popup "$2"
        ;;
    "")
        mkdir -p "$(dirname "$LOG_FILE")"
        # Stray stderr scrolls the popup and cuts off fzf's top border.
        run_picker 2>>"$LOG_FILE"
        ;;
    *) printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
