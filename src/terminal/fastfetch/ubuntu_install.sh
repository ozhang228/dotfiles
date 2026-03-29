is_installed()  { command -v "$1" &>/dev/null; }

if is_installed fastfetch; then
echo "Fastfetch already installed"
return
fi

if ! is_installed add-apt-repository; then
echo "Installing add-apt-repository"
sudo apt update -y
sudo apt install -y software-properties-common
fi
sudo add-apt-repository -y fastfetch
done
