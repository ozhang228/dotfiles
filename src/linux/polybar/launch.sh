#!/bin/bash

killall -q polybar
deadline=$((SECONDS + 5))
while pgrep -u "$UID" -x polybar >/dev/null; do
    if (( SECONDS >= deadline )); then
        echo "polybar did not stop within 5 seconds" >&2
        exit 1
    fi
    sleep 0.1
done

> /tmp/polybar.log

for m in $(polybar --list-monitors | cut -d":" -f1); do
    MONITOR=$m polybar --reload main -c $HOME/dotfiles/src/linux/polybar/config.ini 2>&1 | tee -a /tmp/polybar.log & disown
done
