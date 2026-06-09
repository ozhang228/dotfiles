set -gx NVM_DIR "$HOME/.nvm"
if test -s "$NVM_DIR/nvm.sh"
    bass "source $NVM_DIR/nvm.sh && nvm use default"
end
