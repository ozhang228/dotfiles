# Window Setup
$env:OS = "Windows"
Write-Host "Environment variable set: OS=$($env:OS)"


# -- Install Dependencies --
$wingetApps = @(
    # Core
    "Neovim.Neovim",
    "JesseDuffield.lazygit",
    "wez.wezterm",
    "Starship.Starship",
    # CLI
    "sharkdp.fd",
    "BurntSushi.ripgrep.MSVC",
    "ajeetdsouza.zoxide",
    "junegunn.fzf",
    "jqlang.jq",
    "GitHub.cli",
    "fastfetch",
    "Git.Git",
    # Tiling Manager
    "glzr-io.glazewm",
    # Languages
    "Python.Python.3.12",
    "astral-sh.uv",
    "OpenJS.NodeJS",
    "AmN.yasb"
    # Misc
    "Microsoft.Powershell.Preview",
    "Microsoft.Powertoys",
    "DEVCOM.JetBrainsMonoNerdFont"
)

foreach ($appId in $wingetApps) {
    $installed = winget list --id=$appId -e | Select-String $appId

    if ($installed) {
        Write-Host "$appId already installed. Skipping..."
    } else {
        Write-Host "Installing $appId"
        winget install $appId
    }
}

$modules = @(
    "PowerShellGet",
    "PSReadLine",
    "PSFzf"
)

foreach ($module in $modules) {
    $installed = Get-Module -ListAvailable -Name $module

    if ($installed) {
        Write-Host "$module already installed. Skipping..."
    } else {
        Write-Host "Installing $module"
        Install-Module -Name $module -Force
    }
}

$npmPackages = @(
    "prettier"
)

Write-Host "🔧 Installing global npm packages via npm…"

foreach ($pkg in $npmPackages) {
  npm list -g --depth=0 $pkg 2>$null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] $pkg is already installed. Skipping..."
  } else {
    Write-Host "[INSTALL] Installing $pkg..."
    npm install -g $pkg
  }
}

# -- Git 
git config --global user.name "Oscar Zhang"
git config --global user.email "oscarzhang228@gmail.com"

# -- Setup Dotfiles --
$dotfiles = Join-Path $home "dotfiles"

$symlinks = @(
    @{ Source = "core\nvim"; Destination = Join-Path $env:LOCALAPPDATA "nvim" }
    @{ Source = "core\wezterm"; Destination = Join-Path $home ".config\wezterm"}
    @{ Source = "core\starship"; Destination = Join-Path $home ".config\starship"}
    @{ Source = "core\lazygit"; Destination = Join-Path $env:LOCALAPPDATA "lazygit"}
    @{ Source = "dist\windows\Microsoft.PowerShell_profile.ps1"; Destination = $profile }
    @{ Source = "dist\windows\clangd"; Destination = Join-Path $env:LOCALAPPDATA "clangd"}
    @{ Source = "dist\windows\glazewm\config.yaml"; Destination = Join-Path $home ".glzr\glazewm\config.yaml"}
    @{ Source = "dist\windows\yasb"; Destination = Join-Path $home ".config\yasb"}
)

if ($isAdmin) {
    foreach ($link in $symlinks) {
        $sourcePath = Join-Path $dotfiles $link.Source
        $destinationPath = $link.Destination
	    
        # Remove existing config if it exists
        if (Test-Path $destinationPath) {
            Remove-Item $destinationPath -Recurse -Force
	        Write-Host "Removed existing: $destinationPath"
        }

        # Create symlink
        sudo New-Item -ItemType SymbolicLink -Path $destinationPath -Target $sourcePath
        Write-Host "Symlink created: $destinationPath -> $sourcePath"
    }
} else {
    Write-Host "Detected not in administrator mode, symlinks skipped"
}

Write-Host "🔧 Setup complete"

