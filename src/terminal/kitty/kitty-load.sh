#!/usr/bin/env bash
# Load a kitty session file into the CURRENT kitty instance (adds tabs instead
# of spawning a new kitty). Must be run from inside a kitty that has
# allow_remote_control=yes and listen_on set.
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
import os, subprocess, sys, shlex
f = sys.argv[1]
cwd = os.path.expanduser("~")
pending_title = None
def launch(title, cwd, cmd):
    args = ["kitty", "@", "launch", "--type=tab"]
    if title:
        args += ["--tab-title", title]
    if cwd:
        args += ["--cwd", os.path.expanduser(cwd)]
    if cmd:
        args += cmd
    subprocess.run(args, check=False)
with open(f) as fh:
    for line in fh:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        head, _, rest = line.partition(" ")
        if head == "new_tab":
            pending_title = rest.strip() or None
        elif head == "cd":
            cwd = rest.strip() or cwd
        elif head == "launch":
            cmd = shlex.split(rest) if rest else []
            launch(pending_title, cwd, cmd)
            pending_title = None
PY
