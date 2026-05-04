function claude-branch-resume --description "Resume (or create) a Claude Code session bound to the current git branch"
    set -l branch (git branch --show-current 2>/dev/null)
    if test -z "$branch"
        echo "claude-branch-resume: not on a git branch" >&2
        return 1
    end

    set -l repo (git rev-parse --show-toplevel)
    set -l remote (git config --get remote.origin.url)
    set -l session_id (uuidgen --sha1 --namespace @url --name "$remote:$branch")

    set -l remote_key $remote
    test -z "$remote_key"; and set remote_key $repo
    set -l shared_slug (printf '%s' "$remote_key" | sha1sum | string sub -l 12)
    set -l shared_dir ~/.claude/projects/-shared-$shared_slug
    set -l sanitized (echo $repo | sed 's/[/.]/-/g')
    set -l project_dir ~/.claude/projects/$sanitized

    mkdir -p $shared_dir
    if test -L $project_dir
        if test (readlink $project_dir) != $shared_dir
            ln -sfn $shared_dir $project_dir
        end
    else
        if test -d $project_dir
            find $project_dir -mindepth 1 -maxdepth 1 -exec mv -t $shared_dir {} +
            rm -rf $project_dir
        end
        ln -sfn $shared_dir $project_dir
    end

    set -l existing (find $shared_dir -maxdepth 1 -name "$session_id.jsonl" -print -quit 2>/dev/null)
    pushd $repo
    if test -n "$existing"
        claude --resume $session_id $argv
    else
        claude --session-id $session_id $argv
    end
    popd
end
