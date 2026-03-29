is_installed()  { command -v "$1" &>/dev/null; }

if is_installed nvim; then
echo "Neovim already installed"
return
fi
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo mv /opt/nvim-linux-x86_64 /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
rm -f nvim-linux-x86_64.tar.gz
