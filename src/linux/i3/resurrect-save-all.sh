#!/usr/bin/env bash
# Save every existing i3 workspace via i3-resurrect.
set -euo pipefail

i3-msg -t get_workspaces | python3 -c '
import json, subprocess, sys
for ws in json.load(sys.stdin):
    subprocess.run(["i3-resurrect", "save", "-w", ws["name"], "--swallow=class,instance"], check=False)
'
