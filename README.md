# Dots and Setup Scripts

My dots and setup scripts for linux and windows

# Currently Updated

- **Windows + Arch WSL**
- **Manjaro**
- **Ubuntu**

# Config

- **Terminals**
  - Wezterm + ZShell
  - Kitty *Main* + ZShell
- **CLI Tools**
  - Starship Prompt
  - Neovim
  - FastFetch
  - fd, fzf, ripgrep, jq, prettier
  - Zoxide
  - LazyGit
  - Github CLI
  - C Compilers
- **Misc**
  - JetbrainsNerdFont Mono
- **Window Managers**
  - GlazeWM + Yasb (Windows)
  - Hyprland + Hyprpanel (Manjaro)
  - I3 + Polybar (Ubuntu)
- **App Launcher**
  - Powertoys Run (Windows)
  - Rofi (Linux)
- **Browsers**
  - Vivaldi
  - Google-Chrome
- **Windows Specific**
  - Powershell 7
  - PSReadLine
  - PowerShellGet
  - PSFzf

# Manual Setup Needed

## General

- Downloading Vivaldi Browser
- Github setup (gh auth login)
- Copilot Setup (Copilot auth in nvim)
- Run Tests
  - audio, camera, screen share
  - bluetooth, wifi 
- Disable mouse acceleration
- Setup Reasonable Defaults for Shutting Down Laptop on lid close

## Windows

- Powertoys Setup 
  - Keyboard Manager
    - Remap Caps Lock -> Esc
    - Remap <C-Shift-Caps Lock> -> Caps Lock
  - Powertoys Run: Win + Space for open
- WSL (wsl --install archlinux) 
- GlazeWM 
  - add to startup and delete Zebar

## Arch WSL

- User Setup 
  - `useradd -m -G wheel oscar`
  - `passwd root` / `passwd oscar` to set some passwords
  - `pacman -Sy sudo nvim git` so I can access sudo in user, nvim to edit wheel group, and git to pull repo
  - `EDITOR=nvim visudo` and uncomment out `%wheel ALL=(ALL) ALL` to give wheel user group sudo permissions with password
- Setup Locale to be en_US 
  - uncomment the locale in etc/locale.gen
  - run `locale-gen` and then `locale`
- Setup WSL Defaults
  ```bash
  wsl --set-default archlinux # default distro
  wsl --manage archlinux --set-default-user oscar # set default user (might need to update wsl)
  ```

## Ubuntu

- Remap caps to escape by doing `sudo nvim /etc/default/keyboard` and changing `XKBOPTIONS="caps:swapescape"`
- Edit etc/systemd/logind.conf with sudo nvim and change HandleLidSwitch to shutdown, HandleLidSwitchExternalPower to suspend, and IdleAction to shudown with the IdleActionSec=5min
- solaar for unifying receivers if needed

## Manjaro

- Edit etc/systemd/logind.conf with sudo nvim and change HandleLidSwitch to shutdown, HandleLidSwitchExternalPower to suspend, and IdleAction to shudown with the IdleActionSec=5min
- might need to do vivaldi:flags and set preferred ozone platform to wayland and disabling ui scaling

