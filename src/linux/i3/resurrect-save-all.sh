#!/usr/bin/env bash
# Save every existing i3 workspace via i3-resurrect. Match windows by class and
# instance so dynamic titles do not leave stale placeholders. Remove Chrome
# launch commands because one --restore-last-session process owns restoration
# for every browser window.
#
# On a per-workspace save failure, delete that workspace's previous save so a
# stale snapshot never sits there looking valid for restore-all.sh to pick up.
set -euo pipefail

export WS_JSON
WS_JSON="$(i3-msg -t get_workspaces)"

python3 - <<'PY'
import json
import os
import pathlib
import subprocess

d = pathlib.Path.home() / ".i3/i3-resurrect"
saved, failed = [], []

for ws in json.loads(os.environ["WS_JSON"]):
    name = ws["name"]
    result = subprocess.run(
        ["i3-resurrect", "save", "-w", name, "--swallow=class,instance"],
        check=False,
    )
    if result.returncode == 0:
        saved.append(name)
    else:
        failed.append(name)
        for f in (d / f"workspace_{name}_layout.json", d / f"workspace_{name}_programs.json"):
            f.unlink(missing_ok=True)

summary = f"i3-resurrect save: {len(saved)} saved, {len(failed)} failed"
if failed:
    summary += f" ({', '.join(failed)}) - stale snapshot deleted"
print(summary)
PY

python3 - <<'PY'
import json
import pathlib

d = pathlib.Path.home() / ".i3/i3-resurrect"

for f in sorted(d.glob("workspace_*_programs.json")):
    progs = [p for p in json.loads(f.read_text())
             if "chrome" not in ((p.get("command") or [""])[0])]
    f.write_text(json.dumps(progs, indent=2))
PY
