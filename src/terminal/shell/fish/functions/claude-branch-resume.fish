function claude-branch-resume --description "Resume (or create) a Claude Code session bound to the current git branch"
    set -l branch (git branch --show-current 2>/dev/null)
    if test -z "$branch"
        echo "claude-branch-resume: not on a git branch" >&2
        return 1
    end

    set -l repo (git rev-parse --show-toplevel)
    set -l remote (git config --get remote.origin.url)
    set -l session_id (uuidgen --sha1 --namespace @url --name "$remote:$branch")

    set -l existing (find ~/.claude/projects/-home-ozhang--claude -maxdepth 1 -name "$session_id.jsonl" -print -quit 2>/dev/null)
    pushd ~/.claude
    if test -n "$existing"
        claude --resume $session_id --add-dir $repo $argv
    else
        claude --session-id $session_id --add-dir $repo $argv
    end
    popd
end
