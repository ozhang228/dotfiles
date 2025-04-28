# Starship 
Invoke-Expression (&starship init powershell)
$ENV:STARSHIP_CONFIG = "$HOME\.config\Starship\starship.toml"
# Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })


# turn file directory highlighting off
$PSStyle.FileInfo.Directory = ""
# set <C-t> as the keybinding for fzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'
# Put Vi Mode on
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
