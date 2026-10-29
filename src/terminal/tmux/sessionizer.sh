#!/usr/bin/env bash
# Session picker for prefix f.
#
# - Live sessions by last attach (the current one last), then root worktrees
#   without a session.
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
GREEN=$'\e[38;2;166;218;149m'
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

# Emit the path of every registered worktree that still exists on disk.
worktree_paths() {
    local git_dir="$1"
    [ -n "$git_dir" ] || return 0
    git --git-dir="$git_dir" worktree list --porcelain 2>/dev/null \
        | sed -n 's/^worktree //p' \
        | while IFS= read -r path; do
            [ -d "$path" ] && printf '%s\n' "$path"
        done
    return 0
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

# Fill root_worktrees with every worktree under the fixed roots.
collect_root_worktrees() {
    collect_projects
    declare -ga root_worktrees
    local project git_dir

    # Git worktree reads are independent. Run them concurrently so one slow
    # repository does not make every fzf reload wait behind others.
    mapfile -t root_worktrees < <(
        for project in "${projects[@]}"; do
            git_dir="${project_git_dirs[$project]}"
            if [ -n "$git_dir" ]; then
                worktree_paths "$git_dir" &
            else
                printf '%s\n' "$project"
            fi
        done
        wait
    )
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

# Emit one row: kind, session name, path, then the displayed label.
# The label puts the path and age flush right, sized to fzf's width.
emit_row() {
    local kind="$1" name="$2" path="$3" age="$4" icon left right gap
    case "$kind" in
        session) icon="${GREEN}●${RESET}" ;;
        start) icon="${OVERLAY}○${RESET}" ;;
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
    printf '%s\t%s\t%s\t%s %s%*s%s%s%s  %s%3s%s\n' \
        "$kind" "$name" "$path" \
        "$icon" "$name" "$gap" "" \
        "$OVERLAY" "$REPLY" "$RESET" "$SUBTEXT" "$age" "$RESET"
}

list_sessions() {
    local name path last_attached
    declare -A live_paths=() live_names=()

    while IFS=$'\t' read -r name path last_attached; do
        live_names["$name"]=1
        live_paths["$path"]=1
        relative_age "$last_attached"
        emit_row session "$name" "$path" "$REPLY"
    done < <(live_sessions)

    collect_root_worktrees
    local -a startable=()
    for path in "${root_worktrees[@]}"; do
        session_name_for_path "$path"
        [ -n "${live_paths[$path]+x}" ] || [ -n "${live_names[$REPLY]+x}" ] || startable+=("$path")
    done

    [ "${#startable[@]}" -eq 0 ] || while IFS= read -r path; do
        session_name_for_path "$path"
        emit_row start "$REPLY" "$path" ""
    done < <(printf '%s\n' "${startable[@]}" | awk -F / '{ print $NF "\t" $0 }' | sort | cut -f2-)
}

open_entry() {
    local kind="$1" name="$2" path="$3"
    case "$kind" in
        session) open_session "$name" ;;
        start)
            tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$path"
            open_session "$name"
            ;;
        "") ;;
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
    local kind="$1" name="$2" fallback
    case "$kind" in
        session)
            if [ "$name" = "$(current_session)" ]; then
                fallback=$(live_sessions | cut -f1 | grep -Fvx -- "$name" | head -n1 || true)
                [ -z "$fallback" ] || open_session "$fallback"
            fi
            tmux kill-session -t "=$name"
            ;;
        start|"") ;;
    esac
}

# Answer a y/n key: act on a pending kill confirmation, otherwise type the key.
answer_key() {
    local key="$1"
    case "${FZF_PROMPT:-}" in
        "$CONFIRM_PREFIX"*)
            if [ "$key" = y ]; then
                printf 'execute-silent(%s --kill {1} {2})+' "$SCRIPT_Q"
                printf 'reload(%s --list)+' "$SCRIPT_Q"
            fi
            printf 'change-prompt:%s' "$PROMPT"
            ;;
        *) [ "$key" = esc ] && printf 'abort' || printf 'put(%s)' "$key" ;;
    esac
}

confirm_kill() {
    case "$1" in
        session) printf 'change-prompt:%s%s? y/n  ' "$CONFIRM_PREFIX" "$2" ;;
        *) ;;
    esac
}

# Size the popup to the list so short lists leave no empty space.
open_popup() {
    local client="$1" rows client_height client_width height width
    client_width=$(tmux display-message -p -c "$client" '#{client_width}')
    # Just wide enough for the key hints, plus the footer's border and padding.
    footer_hints
    REPLY=$(printf '%s' "$REPLY" | sed 's/\x1b\[[0-9;]*m//g')
    width=$(( ${#REPLY} + 8 ))
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

# Footer key hints, formatted "key ➜ description" like which-key.
footer_hints() {
    local hint=""
    set -- '<CR>' open '<C-n>' 'new from query' '<C-r>' 'rename to query' '<C-x>' kill
    while [ "$#" -ge 2 ]; do
        hint+="${BLUE}$1${RESET} ${OVERLAY}➜${RESET} $2   "
        shift 2
    done
    REPLY="${hint%   }"
}

run_picker() {
    local footer

    footer_hints
    footer=$REPLY

    # Ignore the shell's fzf defaults; their --height=90% draws inline and can cut off the top.
    FZF_DEFAULT_OPTS='' FZF_DEFAULT_OPTS_FILE='' fzf \
        --ansi --layout=reverse --style=full --border=none --gutter=' ' \
        --input-border=rounded --list-border=rounded --footer-border=rounded \
        --delimiter $'\t' --with-nth=4 --tiebreak=index \
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
    --kill) kill_entry "${2:-}" "${3:-}" ;;
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
