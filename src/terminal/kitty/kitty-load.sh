#!/usr/bin/env bash
# Load a kitty session file into the CURRENT kitty instance, replacing all
# existing tabs with the ones in the session file. Must be run from inside a
# kitty that has allow_remote_control=yes and listen_on set.
# Usage: kitty-load.sh <session-file>
set -euo pipefail

file="${1:-}"
if [ -z "$file" ] || [ ! -f "$file" ]; then
    echo "usage: kitty-load <session-file>" >&2
    exit 1
fi

if [ -z "${KITTY_LISTEN_ON:-}" ]; then
    echo "kitty-load: KITTY_LISTEN_ON not set. Run this from inside a kitty with remote control." >&2
    exit 1
fi

python3 - "$file" <<'PY'
import json, os, shlex, subprocess, sys

session_file = sys.argv[1]

ls = json.loads(subprocess.check_output(["kitty", "@", "ls"]))
old_tab_ids = [tab["id"] for oswin in ls for tab in oswin.get("tabs", [])]

cwd = os.path.expanduser("~")
pending_title = None
with open(session_file) as fh:
    for line in fh:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        head, _, rest = line.partition(" ")
        if head in ("new_tab", "tab_title"):
            pending_title = rest.strip() or None
        elif head == "cd":
            cwd = rest.strip() or cwd
        elif head == "launch":
            args = ["kitty", "@", "launch", "--type=tab"]
            if pending_title:
                args += ["--tab-title", pending_title]
            args += ["--cwd", os.path.expanduser(cwd)]
            if rest:
                args += shlex.split(rest)
            subprocess.run(args, check=False)
            pending_title = None

if old_tab_ids:
    match = " or ".join(f"id:{i}" for i in old_tab_ids)
    subprocess.Popen(
        ["kitty", "@", "close-tab", "--match", match],
        start_new_session=True,
    )
PY
