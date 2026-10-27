#!/usr/bin/env bash
set -euo pipefail

if command -v systemctl >/dev/null; then
    while IFS='=' read -r name value; do
        case "$name" in
            DISPLAY) export DISPLAY="$value" ;;
            XAUTHORITY) export XAUTHORITY="$value" ;;
        esac
    done < <(systemctl --user show-environment 2>/dev/null)
fi

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
