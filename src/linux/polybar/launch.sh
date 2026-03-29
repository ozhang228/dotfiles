#!/bin/bash

killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

> /tmp/polybar.log

for m in $(polybar --list-monitors | cut -d":" -f1); do
    MONITOR=$m polybar --reload main -c $HOME/dotfiles/src/linux/polybar/config.ini 2>&1 | tee -a /tmp/polybar.log & disown
done
