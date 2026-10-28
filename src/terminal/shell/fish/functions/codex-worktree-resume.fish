function codex-worktree-resume --description "Continue the latest Codex session for the current git worktree (or directory outside git), or start one. --fresh starts a new session."
    set -l fresh 0
    if set -l idx (contains -i -- --fresh $argv)
        set fresh 1
        set -e argv[$idx]
    end

    set -l root (git rev-parse --show-toplevel 2>/dev/null; or pwd)

    set -l has_session 0
    if test $fresh -eq 0
        for session_file in ~/.codex/sessions/**.jsonl
            if head -n1 $session_file | jq -e --arg root "$root" '.type == "session_meta" and .payload.cwd == $root' >/dev/null 2>&1
                set has_session 1
                break
            end
        end
    end

    pushd $root
    # `codex resume --last` picks the most recent session whose cwd is this directory.
    if test $has_session -eq 1
        codex resume --last $argv
    else
        codex $argv
    end
    set -l codex_status $status
    popd
    return $codex_status
end
