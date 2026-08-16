#!/usr/bin/env bash
# Restore every saved i3 workspace via i3-resurrect.
#
# Runs unattended in the login autostart chain (chained with && before
# launching the browser), so a single hung or failing workspace must never
# block the rest of login: each restore gets a timeout, and this script
# always exits 0. Results go to a log file since there's no terminal at
# login and the interactive keybind isn't used.
set -uo pipefail

dir="${HOME}/.i3/i3-resurrect"
log="${dir}/restore.log"
timeout_secs=20

[ -d "$dir" ] || exit 0
mkdir -p "$dir"

{
    echo "--- restore run: $(date -Iseconds) ---"
    restored=0
    failed=0

    for f in "$dir"/workspace_*_layout.json; do
        [ -e "$f" ] || continue
        name="${f##*/workspace_}"
        name="${name%_layout.json}"

        if timeout "${timeout_secs}s" i3-resurrect restore -w "$name"; then
            echo "restored: $name"
            restored=$((restored + 1))
        else
            status=$?
            if [ "$status" -eq 124 ]; then
                echo "timed out after ${timeout_secs}s: $name"
            else
                echo "failed (exit $status): $name"
            fi
            failed=$((failed + 1))
        fi
    done

    echo "restore summary: ${restored} restored, ${failed} failed"
} >>"$log" 2>&1

exit 0
