function codex-worktree-resume --description "Choose a Codex session for the current git worktree (or directory outside git), or start one. --fresh starts a new session."
    set -l fresh 0
    if set -l idx (contains -i -- --fresh $argv)
        set fresh 1
        set -e argv[$idx]
    end

    set -l root (git rev-parse --show-toplevel 2>/dev/null; or pwd)

    set -l has_session 0
    if test $fresh -eq 0
        set has_session (python3 -c '
import json
import pathlib
import sys

for path in (pathlib.Path.home() / ".codex/sessions").rglob("*.jsonl"):
    try:
        with path.open() as session_file:
            metadata = json.loads(session_file.readline())
        if metadata.get("type") == "session_meta" and metadata.get("payload", {}).get("cwd") == sys.argv[1]:
            print(1)
            break
    except (OSError, ValueError):
        continue
else:
    print(0)
' $root); or return $status
    end

    pushd $root
    # The resume picker filters to sessions whose cwd is this directory.
    if test $has_session -eq 1
        codex resume $argv
    else
        codex $argv
    end
    set -l codex_status $status
    popd
    return $codex_status
end
