#!/usr/bin/env bash
# Save every existing i3 workspace via i3-resurrect, then strip Chrome from the
# saved state entirely. i3 can't tell two same-profile Chrome windows apart
# (identical class/instance, --class is ignored), so letting i3-resurrect place
# them is a coin flip. Instead we let Chrome restore its own windows via
# --restore-last-session (launched once at login from the i3 config) and keep
# i3-resurrect for everything else (kitty, slack).
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

def is_chrome_swallow(node):
    for s in node.get("swallows") or []:
        if "hrome" in (s.get("class") or ""):
            return True
    return False

def strip_chrome_nodes(nodes):
    kept = []
    for n in nodes:
        if n.get("nodes"):
            n["nodes"] = strip_chrome_nodes(n["nodes"])
        if is_chrome_swallow(n) and not n.get("nodes"):
            continue
        if "swallows" not in n and not n.get("nodes"):
            continue
        kept.append(n)
    return kept

for f in sorted(d.glob("workspace_*_programs.json")):
    progs = [p for p in json.loads(f.read_text())
             if "chrome" not in ((p.get("command") or [""])[0])]
    f.write_text(json.dumps(progs, indent=2))

for f in sorted(d.glob("workspace_*_layout.json")):
    layout = json.loads(f.read_text())
    if "nodes" in layout:
        layout["nodes"] = strip_chrome_nodes(layout["nodes"])
    f.write_text(json.dumps(layout, indent=2))
PY
