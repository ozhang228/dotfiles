function claude-worktree-resume --description "Continue the latest Claude Code session for the current git worktree (or directory outside git), or start one. --fresh starts a new session."
    set -l fresh 0
    if set -l idx (contains -i -- --fresh $argv)
        set fresh 1
        set -e argv[$idx]
    end

    set -l root (git rev-parse --show-toplevel 2>/dev/null; or pwd)
    # Claude Code keeps each directory's sessions under its path with every non-alphanumeric character replaced by "-".
    set -l project_dir ~/.claude/projects/(string replace -ra '[^a-zA-Z0-9]' - -- $root)

    pushd $root
    if test $fresh -eq 0; and count $project_dir/*.jsonl >/dev/null
        claude --continue $argv
    else
        claude $argv
    end
    set -l claude_status $status
    popd
    return $claude_status
end
