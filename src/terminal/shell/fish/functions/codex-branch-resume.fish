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

    if test $fresh -eq 1
        rm -f $tracked_file
        echo "Forgot tracked session for $branch — starting fresh"
    end

    set -l session_id (cat $tracked_file 2>/dev/null)

    pushd $repo
    if test -n "$session_id"
        codex resume $session_id $argv
    else
        codex $argv
    end

    for f in (find ~/.codex/sessions -type f -name "*.jsonl" -printf '%T@ %p\n' 2>/dev/null | sort -rn | string split -m1 -f2 " ")
        if test "$(head -n1 $f | jq -r '.payload.cwd // empty' 2>/dev/null)" = "$repo"
            head -n1 $f | jq -r '.payload.id' 2>/dev/null > $tracked_file
            break
        end
    end
    popd
end
