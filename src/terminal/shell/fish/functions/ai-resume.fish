function ai-resume --description "Resume the current worktree's conversation with --agent pi, claude, or codex. --fresh starts a new session."
    uv run --no-project --script ~/dotfiles/src/terminal/shell/scripts/ai-resume.py $argv
end
