function codex-worktree-resume --description "Continue the latest Codex session for the current git worktree (or directory outside git), or start one. --fresh starts a new session."
    set -l fresh 0
    if set -l idx (contains -i -- --fresh $argv)
        set fresh 1
        set -e argv[$idx]
    end

    set -l root (git rev-parse --show-toplevel 2>/dev/null; or pwd)

    set -l session_id ""
    if test $fresh -eq 0
        set session_id (python3 -c '
import json
import pathlib
import sys

latest_session = None
for path in (pathlib.Path.home() / ".codex/sessions").rglob("*.jsonl"):
    try:
        with path.open() as session_file:
            metadata = json.loads(session_file.readline())
        if not isinstance(metadata, dict):
            continue
        payload = metadata.get("payload")
        if (
            metadata.get("type") == "session_meta"
            and isinstance(payload, dict)
            and payload.get("cwd") == sys.argv[1]
        ):
            session_id = payload.get("id")
            if isinstance(session_id, str) and session_id:
                session = (path.stat().st_mtime_ns, session_id)
                if latest_session is None or session[0] > latest_session[0]:
                    latest_session = session
    except (OSError, ValueError):
        continue
print(latest_session[1] if latest_session else "")
' $root); or return $status
    end

    pushd $root
    # Resolve the latest session by its recorded cwd so resume is explicitly worktree-scoped.
    if test -n "$session_id"
        codex resume $session_id $argv
    else
        codex $argv
    end
    set -l codex_status $status
    popd
    return $codex_status
end
