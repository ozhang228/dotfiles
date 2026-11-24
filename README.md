# Dotfiles

Dotfiles with setup script

## Requirements

- `uv` and `python` to run the setup script
  - curl -LsSf https://astral.sh/uv/install.sh | sh
- either `Mac`, `Ubuntu`, or `Manjaro` (could probably work for any arch based distro)
- must be cloned under `$HOME/dotfiles`

## Manual Setup

- for linux setups, run tests to confirm all of these functions work
  - audio
  - camera
  - screen share
  - bluetooth
  - wifi

- Github setup (gh auth login)
- AI Coding Assistant Setup
  - clone `/ai` github repository
  - setup rules to read ai files

- ubuntu
  - setup monitors in arandr then save in autorandr

- manjaro laptop power (needs sudo, not managed by `symlinks.json`; battery service assumes `BAT0` with charge thresholds, e.g. ThinkPad)
  - `sudo install -Dm644 ~/dotfiles/src/linux/manjaro/system/logind-lid.conf /etc/systemd/logind.conf.d/lid.conf` (lid close ignored on AC or docked; applies after reboot)
  - `sudo install -Dm644 ~/dotfiles/src/linux/manjaro/system/battery-charge-limit.service /etc/systemd/system/battery-charge-limit.service`
  - `sudo systemctl enable --now battery-charge-limit.service` (charge between 75% and 80%)
