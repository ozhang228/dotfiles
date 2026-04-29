#!/usr/bin/env bash
# Restore every saved i3 workspace via i3-resurrect.
set -euo pipefail

dir="${HOME}/.i3/i3-resurrect"
[ -d "$dir" ] || exit 0

for f in "$dir"/workspace_*_layout.json; do
    [ -e "$f" ] || continue
    name="${f##*/workspace_}"
    name="${name%_layout.json}"
    i3-resurrect restore -w "$name" || true
done
