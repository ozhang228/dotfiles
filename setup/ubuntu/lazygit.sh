is_installed()  { command -v "$1" &>/dev/null; }

if is_installed lazygit; then
echo "lazygit already installed."
return
fi
LAZYGIT_VERSION="$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": *"v\K[^"]*')"
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install -D lazygit -t /usr/local/bin/
rm -f lazygit lazygit.tar.gz
