# Window Setup
$env:OS = "Windows"
Write-Host "Environment variable set: OS=$($env:OS)"

# -- Setup Dotfiles --

$dotfiles = Join-Path $home "dotfiles"

$symlinks = @(
    @{ Source = "core\nvim"; Destination = Join-Path $env:LOCALAPPDATA "nvim" }
    @{ Source = "core\wezterm"; Destination = Join-Path $home ".config\wezterm"}
    @{ Source = "core\starship"; Destination = Join-Path $home ".config\starship"}
    @{ Source = "core\lazygit"; Destination = Join-Path $env:LOCALAPPDATA "lazygit"}
    @{ Source = "dist\windows\Microsoft.PowerShell_profile.ps1"; Destination = $profile }
    @{ Source = "dist\windows\clangd"; Destination = Join-Path $env:LOCALAPPDATA "clangd"}
)

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

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
    New-Item -ItemType SymbolicLink -Path $destinationPath -Target $sourcePath
    Write-Host "Symlink created: $destinationPath -> $sourcePath"
    }
} else {
    Write-Host "Detected not in administrator mode, symlinks skipped"
}

# -- Install Dependencies --
$wingetApps = @(
    "Neovim.Neovim",
    "sharkdp.fd",
    "BurntSushi.ripgrep.MSVC",
    "JesseDuffield.lazygit",
    "wez.wezterm",
    "Starship.Starship",
    "ajeetdsouza.zoxide",
    "DEVCOM.JetBrainsMonoNerdFont",
    "junegunn.fzf",
    "jqlang.jq",
    "glzr-io.glazewm"
    "OpenJS.NodeJS"
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
    # attempt to list; suppress stderr
    npm list -g --depth=0 $pkg 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $pkg is already installed. Skipping…"
    }
    else {
        Write-Host "📦 Installing $pkg…"
        npm install -g $pkg
    }
}
