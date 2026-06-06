#!/bin/bash
random_pick=$(find "$HOME/dotfiles/imgs/wallpapers/" -type f \( -name "*.png" -o -name "*.jpg" \) | shuf -n1)
sed -e "s~<wp>~${random_pick}~g" "$HOME/.config/hypr/hyprpaper_template.conf" > "$HOME/.config/hypr/hyprpaper.conf"
