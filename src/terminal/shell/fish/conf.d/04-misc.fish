if status is-interactive

fish_config theme choose "GitHub Light High Contrast"
if not pgrep -x copyq &>/dev/null
    copyq --start-server
end

end
