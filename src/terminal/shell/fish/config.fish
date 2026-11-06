if status is-interactive
end

if test -d "$HOME/.local/share/pi-sandbox/bin"
    fish_add_path --path --prepend --move "$HOME/.local/share/pi-sandbox/bin"
end
