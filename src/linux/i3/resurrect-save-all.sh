#!/usr/bin/env bash
# Save every existing i3 workspace via i3-resurrect, then patch chrome entries
# to include --profile-directory="Profile 1" --restore-last-session so restore
# actually reopens tabs.
set -euo pipefail

i3-msg -t get_workspaces | python3 -c '
import json, subprocess, sys
for ws in json.load(sys.stdin):
    subprocess.run(
        ["i3-resurrect", "save", "-w", ws["name"], "--swallow=class,instance"],
        check=False,
    )
'

python3 - <<'PY'
import json, pathlib
d = pathlib.Path.home() / ".i3/i3-resurrect"
for f in sorted(d.glob("workspace_*_programs.json")):
    progs = json.loads(f.read_text())
    changed = False
    for p in progs:
        cmd = p.get("command") or []
        if cmd and "chrome" in cmd[0] and not any(a.startswith("--profile-directory") for a in cmd):
            cmd[:] = [cmd[0], "--profile-directory=Profile 1", "--restore-last-session"]
            changed = True
    if changed:
        f.write_text(json.dumps(progs, indent=2))
PY
