# Autostart tmux in normal interactive terminals. Skip when already inside
# tmux, or inside an nvim floating terminal (nvim sets $NVIM for its jobs).
if status is-interactive
    and not set -q TMUX
    and not set -q NVIM
    and type -q tmux

    set -l session_name (basename $PWD | tr '.:' '__')

    if tmux has-session -t $session_name 2>/dev/null
        exec tmux attach-session -t $session_name
    else
        exec tmux new-session -s $session_name -c $PWD
    end
end
