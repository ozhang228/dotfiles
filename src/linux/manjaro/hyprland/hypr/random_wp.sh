#! bin/bash
# Pick random wallpaper
random_pick=$(find "$HOME/dotfiles/imgs/wallpapers/" -type f -name "*.png" -o -name "*.jpg" | shuf -n1)

# Replace the placeholder in template and save to .conf file
sed -e "s~<wp>~${random_pick}~g" $HOME/dotfiles/dist/unix/hypr/hyprpaper_template.conf > $HOME/dotfiles/dist/unix/hypr/hyprpaper.conf
