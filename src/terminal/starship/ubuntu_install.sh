is_installed()  { command -v "$1" &>/dev/null; }

if is_installed starship; then
echo "Starship already installed."
return
fi
curl -fsSL https://starship.rs/install.sh | bash -s -- -y
