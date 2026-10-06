if status is-interactive

fish_config theme choose "Gruvbox Light Hard"
if not pgrep -x copyq &>/dev/null
    copyq --start-server
end

end
