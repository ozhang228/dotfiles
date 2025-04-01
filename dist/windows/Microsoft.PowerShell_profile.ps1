$env:OS = "Windows"

# Starship 
Invoke-Expression (&starship init powershell)
$ENV:STARSHIP_CONFIG = "$HOME\.config\Starship\starship.toml"

# Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# turn file directory highlighting off
$PSStyle.FileInfo.Directory = ""

# set <C-t> as the keybinding for fzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'
