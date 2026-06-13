# Autostart tmux in normal interactive terminals, always attaching to a
# shared "default" session. Skip when already inside tmux, or inside an
# nvim floating terminal (nvim sets $NVIM for its jobs).
if status is-interactive
    and not set -q TMUX
    and not set -q NVIM
    and type -q tmux

    if tmux has-session -t default 2>/dev/null
        exec tmux attach-session -t default
    else
        exec tmux new-session -s default -c ~
    end
end
