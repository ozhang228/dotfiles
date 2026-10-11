if status is-interactive

fish_config theme choose "Catppuccin Macchiato"
if not pgrep -x copyq &>/dev/null
    copyq --start-server
end

end
