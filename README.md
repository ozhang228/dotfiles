# Dotfiles

Dotfiles with setup script

## Requirements

- `uv` and `python` to run the setup script
  - curl -LsSf https://astral.sh/uv/install.sh | sh
- either `Mac`, `Ubuntu`, or `Manjaro` (could probably work for any arch based distro)
- must be cloned under `$HOME/dotfiles`

# Todos

- cleanup i3
  - should have a session setup and a toolbar and better monitor handling
- fish stuff
- emulate all setup script duties
- automate manual setups
  - **General**
    - Github setup (gh auth login)
    - AI Coding Assistant Setup (Opencode, Codex, etc.)
    - Run Tests
      - audio, camera, screen share
      - bluetooth, wifi
    - remap caps to escape

  - **Ubuntu**
    - Remap caps to escape by doing `sudo nvim /etc/default/keyboard` and changing `XKBOPTIONS="caps:swapescape"`

- try pet cli tool

- write about manual setup
  - ubuntu monitor handling with arandr then save in autorandr
