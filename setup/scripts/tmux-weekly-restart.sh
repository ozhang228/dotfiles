#!/usr/bin/env bash
# Idempotent install of the weekly tmux restart timer (systemd user units).
set -euo pipefail

UNIT_DIR="$HOME/dotfiles/src/terminal/tmux/systemd"

systemctl --user link "$UNIT_DIR/tmux-weekly-restart.service"
systemctl --user enable --now "$UNIT_DIR/tmux-weekly-restart.timer"
