function codex-branch-resume --description "Resume (or create) a Codex session bound to the current git branch. Use --fresh to forget the tracked session and start clean."
    set -l fresh 0
    if set -l idx (contains -i -- --fresh $argv)
        set fresh 1
        set -e argv[$idx]
    end

    set -l branch (git branch --show-current 2>/dev/null)
    if test -z "$branch"
        echo "codex-branch-resume: not on a git branch" >&2
        return 1
    end

    set -l repo (git rev-parse --show-toplevel)
    set -l remote (git config --get remote.origin.url)
    set -l remote_key $remote
    test -z "$remote_key"; and set remote_key $repo
    set -l branch_key (printf '%s:%s' "$remote_key" "$branch" | sha1sum | string sub -l 12)

    mkdir -p ~/.codex/branch-sessions
    set -l tracked_file ~/.codex/branch-sessions/$branch_key
    set -l session_matches_branch '
        .type == "session_meta"
        and (.payload.git.branch // "") == $branch
        and (if $remote == "" then
            (.payload.cwd // "") == $repo
        else
            (.payload.git.repository_url // "") == $remote
        end)
    '

    if test $fresh -eq 1
        rm -f $tracked_file
        echo "Forgot tracked session for $branch — starting fresh"
    end

    set -l session_id (cat $tracked_file 2>/dev/null)

    if test -n "$session_id"
        set -l session_file (find ~/.codex/sessions -type f -name "*-$session_id.jsonl" -print -quit 2>/dev/null)
        if test -z "$session_file"
            set session_id
            rm -f $tracked_file
        else if not head -n1 $session_file | jq -e --arg remote "$remote" --arg branch "$branch" --arg repo "$repo" $session_matches_branch >/dev/null 2>&1
            set session_id
            rm -f $tracked_file
        end
    end

    if test -z "$session_id" -a $fresh -eq 0
        for session_file in (find ~/.codex/sessions -type f -name "*.jsonl" -printf '%T@ %p\n' 2>/dev/null | sort -rn | string split -m1 -f2 " ")
            if head -n1 $session_file | jq -e --arg remote "$remote" --arg branch "$branch" --arg repo "$repo" $session_matches_branch >/dev/null 2>&1
                set session_id (head -n1 $session_file | jq -r '.payload.id // .payload.session_id // empty')
                break
            end
        end
    end

    if not pushd $repo >/dev/null
        return 1
    end
    if test -n "$session_id"
        codex resume $session_id $argv
    else
        codex $argv
    end
    set -l codex_status $status

    for session_file in (find ~/.codex/sessions -type f -name "*.jsonl" -printf '%T@ %p\n' 2>/dev/null | sort -rn | string split -m1 -f2 " ")
        if head -n1 $session_file | jq -e --arg remote "$remote" --arg branch "$branch" --arg repo "$repo" $session_matches_branch >/dev/null 2>&1
            set -l latest_session_id (head -n1 $session_file | jq -r '.payload.id // .payload.session_id // empty')
            set -l pending_file (mktemp "$tracked_file.tmp.XXXXXX")
            if test -n "$latest_session_id" -a -n "$pending_file"
                printf '%s\n' $latest_session_id >$pending_file
                mv $pending_file $tracked_file
            else if test -n "$pending_file"
                rm -f $pending_file
            end
            break
        end
    end
    popd >/dev/null
    return $codex_status
end
