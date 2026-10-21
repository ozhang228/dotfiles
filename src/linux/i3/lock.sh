#!/usr/bin/env bash
set -euo pipefail

paused=
cleanup() {
    if [[ -n $paused ]]; then dunstctl set-paused "$paused"; fi
}
trap cleanup EXIT

if command -v dunstctl >/dev/null; then
    paused=$(dunstctl is-paused)
    dunstctl set-paused true
fi

i3lock --nofork --color=24273a "$@"
