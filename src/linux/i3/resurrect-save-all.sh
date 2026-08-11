#!/usr/bin/env bash
# Save every existing i3 workspace via i3-resurrect. Keep Chrome's title-aware
# layout placeholders so its restored windows return to their saved workspaces,
# but remove Chrome launch commands because one --restore-last-session process
# owns restoration for every browser window.
set -euo pipefail

i3-msg -t get_workspaces | python3 -c '
import json, subprocess, sys
for ws in json.load(sys.stdin):
    subprocess.run(
        ["i3-resurrect", "save", "-w", ws["name"], "--swallow=class,instance,title"],
        check=False,
    )
'

python3 - <<'PY'
import json
import pathlib

d = pathlib.Path.home() / ".i3/i3-resurrect"

for f in sorted(d.glob("workspace_*_programs.json")):
    progs = [p for p in json.loads(f.read_text())
             if "chrome" not in ((p.get("command") or [""])[0])]
    f.write_text(json.dumps(progs, indent=2))
PY
