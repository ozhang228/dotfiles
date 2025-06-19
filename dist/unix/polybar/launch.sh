killall -q polybar

polybar main -c ./config.ini 2>&1 | tee -a /tmp/polybar.log & disown

