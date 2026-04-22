function claude-branch-resume --description "Resume (or create) a Claude Code session bound to the current git branch"
    set -l branch (git branch --show-current 2>/dev/null)
    if test -z "$branch"
        echo "claude-branch-resume: not on a git branch" >&2
        return 1
    end

    set -l repo (git rev-parse --show-toplevel)
    set -l session_id (uuidgen --sha1 --namespace @url --name "$repo:$branch")

    set -l existing (find ~/.claude/projects -maxdepth 2 -name "$session_id.jsonl" -print -quit 2>/dev/null)
    if test -n "$existing"
        claude --resume $session_id $argv
    else
        claude --session-id $session_id $argv
    end
end
