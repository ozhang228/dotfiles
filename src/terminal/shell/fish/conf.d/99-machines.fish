set -l machine_config $HOME/.config/fish/conf.d/machines/(hostname).fish
test -f $machine_config && source $machine_config
