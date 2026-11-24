if command -v yay &>/dev/null; then
echo "yay already present"
return
fi

sudo pacman -S --needed -- base-devel git
rm -rf \"$HOME/yay\"
git clone https://aur.archlinux.org/yay.git \"$HOME/yay\"
(
cd "$HOME/yay"
makepkg -si
)
rm -rf "$HOME/yay"
echo "yay installed"
