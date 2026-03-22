# Dotfiles

Dotfiles with setup script

## Requirements

- `uv` to run the setup script

- Currently Maintained
  - Ubuntu
  - Manjaro
  - Mac

- Manual Setup Needed
  - **General**
    - Github setup (gh auth login)
    - AI Coding Assistant Setup (Opencode, Codex, etc.)
    - Run Tests
      - audio, camera, screen share
      - bluetooth, wifi
    - remap caps to escape

  - **Ubuntu**
    - Remap caps to escape by doing `sudo nvim /etc/default/keyboard` and changing `XKBOPTIONS="caps:swapescape"`
    - Edit etc/systemd/logind.conf with sudo nvim and change HandleLidSwitch to shutdown, HandleLidSwitchExternalPower to suspend, and IdleAction to shudown with the IdleActionSec=5min
    - solaar for unifying receivers if needed
