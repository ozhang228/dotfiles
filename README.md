# Dotfiles

Dotfiles with setup script

## Requirements

- `uv` and `python` to run the setup script
- either `Mac`, `Ubuntu`, or `Manjaro` (could probably work for any arch based distro)
- must be cloned under `$HOME/dotfiles`

# Todos

- config tooling
  - each tool defines what it requires
    - symlinks
    - packages
    - env variables being set

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

- cleanup i3
  - should have a session setup and a toolbar and better monitor handling
- try pet cli tool
- make bmark. create bookamrks and press buttons to go to ecah in a tree like pattern
- zshrc alias profiles
