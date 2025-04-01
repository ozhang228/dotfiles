# Window Setup

$dotfiles = Join-Path $home "dotfiles"

$symlinks = @(
    @{ Source = "core\nvim"; Destination = Join-Path $env:LOCALAPPDATA "nvim" }
)


foreach ($link in $symlinks) {
    $sourcePath = Join-Path $dotfiles $link.Source
    $destinationPath = $link.Destination
	
    # Remove existing config if it exists
    if (Test-Path $destinationPath) {
        Remove-Item $destinationPath -Recurse -Force
	Write-Host "Removed existing: $destinationPath"
    }

   # Create symlink
   New-Item -ItemType SymbolicLink -Path $destinationPath -Target $sourcePath
   Write-Host "Symlink created: $destinationPath -> $sourcePath"
}

