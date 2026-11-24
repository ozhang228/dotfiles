# Opt-in tmux autostart. Defines `tmux_autostart` but does NOT run it here;
# machines that want tmux on login call it from their machines/<hostname>.fish.
#
# Attaches to a shared "default" session. No-ops when already inside tmux, or
# inside an nvim floating terminal (nvim sets $NVIM for its jobs).
function tmux_autostart
    if status is-interactive
        and isatty stdin
        and isatty stdout
        and not set -q TMUX
        and not set -q NVIM
        and type -q tmux

        if tmux has-session -t default 2>/dev/null
            command tmux attach-session -t default
        else
            command tmux new-session -s default -c ~
        end
        and exit
    end
end
