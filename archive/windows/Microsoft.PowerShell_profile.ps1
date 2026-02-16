# -- Starship 
Invoke-Expression (&starship init powershell)
$ENV:STARSHIP_CONFIG = "$HOME\.config\Starship\starship.toml"

# -- Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# -- fzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'

# -- PSReadLine
# turn file directory highlighting off
$PSStyle.FileInfo.Directory = ""

# Vi Mode
function OnViModeChange
{
  if ($args[0] -eq 'Command')
  {
    Write-Host -NoNewLine "`e[2 q"
  } else
  {
    Write-Host -NoNewLine "`e[6 q"
  }
}
$PSReadLineOptions = @{
  EditMode = "vi"
  HistoryNoDuplicates = $true
  HistorySearchCursorMovesToEnd = $true
  ViModeIndicator = "Script"
  ViModeChangeHandler = $Function:OnViModeChange
}
Set-PSReadLineOption @PSReadLineOptions

Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

# Aliases
Set-Alias -Name ls -Value dir
Set-Alias -Name grep -Value findstr

# Logo
clear
fastfetch --logo $HOME/dotfiles/imgs/pangoro_ascii.txt -c $HOME/dotfiles/core/fastfetch.jsonc
