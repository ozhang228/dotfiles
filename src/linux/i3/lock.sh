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

rule_enabled=
cleanup() {
    if [[ -n $rule_enabled ]]; then
        dunstctl rule screen_locked disable
    fi
}
trap cleanup EXIT

if command -v dunstctl >/dev/null; then
    dunstctl rule screen_locked enable
    rule_enabled=true
    dunstctl close-all
fi

i3lock --nofork --color=24273a "$@"
