# Dotfiles

Dots and setup script 

- Currently Maintained

  - Ubuntu
  - Manjaro
  - Mac

- Manual Setup Needed

  - **General**

    - Github setup (gh auth login)
    - Copilot Setup (Copilot auth in nvim)
    - Run Tests

      - audio, camera, screen share
      - bluetooth, wifi 

    - Disable mouse acceleration
    - wallpapers 
    - remap caps to escape

  - **Ubuntu**

    - Remap caps to escape by doing `sudo nvim /etc/default/keyboard` and changing `XKBOPTIONS="caps:swapescape"`
    - Edit etc/systemd/logind.conf with sudo nvim and change HandleLidSwitch to shutdown, HandleLidSwitchExternalPower to suspend, and IdleAction to shudown with the IdleActionSec=5min
    - solaar for unifying receivers if needed

  - **Manjaro**

    - might need to do vivaldi:flags and set preferred ozone platform to wayland and disabling ui scaling

  - **Windows**

    - Powertoys Setup 

      - Keyboard Manager
        - Swap Caps Lock & Esc
      - Powertoys Run: Win + Space for open

    - WSL (wsl --install archlinux) 
    - GlazeWM 
      - add to startup and delete Zebar

  - **Arch WSL**

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

