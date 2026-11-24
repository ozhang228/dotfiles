#!/usr/bin/env bash
# Idempotent TPM bootstrap.
set -euo pipefail

TPM_DIR="$HOME/.config/tmux/plugins/tpm"

if [ ! -d "$TPM_DIR" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
