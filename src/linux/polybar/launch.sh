killall -q polybar

polybar main -c $HOME/dotfiles/dist/unix/polybar/config.ini 2>&1 | tee -a /tmp/polybar.log & disown

