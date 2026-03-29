#!/bin/bash
WALLPAPER_DIR="$HOME/dotfiles/imgs/wallpapers"

# Pick a random wallpaper
RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

# Set it using feh
feh --bg-fill "$RANDOM_WALLPAPER"
