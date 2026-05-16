if status is-interactive

fish_config theme choose "Rosé Pine Moon"
if not pgrep -x copyq &>/dev/null
    copyq --start-server
end

end
