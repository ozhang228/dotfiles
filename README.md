# Symlinks + Package Install

Basic setup for my dotfiles and packages I generally want on every machine.
Some things missing that I don't need on every machine but generally use:

- [bat](https://github.com/sharkdp/bat): cat with syntax highlighting

## Supported

### Distributions

- **Windows**
- **Arch Linux**

### Languages (by default)

- Python (pip / uv)
- JavaScript (Node.js / npm)
- C++ (gcc)
  - Windows needs to do it manually through msys2

## Config

### Core

- [Neovim](https://github.com/neovim/neovim/blob/master/INSTALL.md)
- [LazyGit](https://github.com/jesseduffield/lazygit)
- [Wezterm](https://wezterm.org/)
- [Starship](https://starship.rs/)
- [fastfetch](https://github.com/fastfetch-cli/fastfetch): Custom preset and logo

### Distribution Specific

#### Windows

- [ClangD](https://clangd.llvm.org/)

## Packages

### Core

- [Neovim](https://github.com/neovim/neovim/blob/master/INSTALL.md)
  - [fd](https://github.com/sharkdp/fd): Find command for pickers
  - [fzf](https://github.com/junegunn/fzf): Fuzzy finding and a dependency for nvim and other cli tools
  - [ripgrep](https://github.com/BurntSushi/ripgrep): Fast regex engine needed for pickers
  - [jq](https://jqlang.org/): JSON Processing engine for rest-client and for general cli use
  - [prettier](https://prettier.io/): HTML Processing engine for rest-client and general formatting
- [LazyGit](https://github.com/jesseduffield/lazygit): Easier git management
- [Wezterm](https://wezterm.org/): Terminal
- [Starship](https://starship.rs/): Prompt
- [Zoxide](https://github.com/ajeetdsouza/zoxide): Magic file navigation
- [JetBrains Mono Font](https://www.jetbrains.com/lp/mono/): Font
- [Github CLI (gh)](https://github.com/cli/cli): GitHub CLI for auth
- [fastfetch](https://github.com/fastfetch-cli/fastfetch): OS Info

### Distribution Specific

#### Windows

- [Powershell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5)
  - [PSReadLine](https://github.com/PowerShell/PSReadLine)
  - [PowerShellget](https://learn.microsoft.com/en-us/powershell/gallery/powershellget/install-powershellget?view=powershellget-3.x)
  - [PSFzf](https://github.com/kelleyma49/PSFzf.git)
- [GlazeWM](https://github.com/glzr-io/glazewm)

#### Linux

- C++ Compilers
  - [build-essentials](https://packages.debian.org/sid/build-essential)
  - [base-devel](https://archlinux.org/packages/core/any/base-devel/)
- [luarocks](https://innovativeinnovation.github.io/ubuntu-setup/lua/luarocks.html)
- [curl](https://curl.se/download.html): call APIs
- [zsh](https://www.zsh.org/)
- [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode): better vi mode for zsh

### Manual Setup

- Vivaldi Browser
- Google Drive App (for my obisidan vaults)
- gh auth login to get into GitHub
- <CMD>Copilot auth</CMD> in nvim to get it setup
- [Desktop Background](https://drive.google.com/drive/folders/1AR-AnlCRXYyG7CBdxvlHCFGqA6IRxXQi)
- Notion
  - **To-Do List & Project Management**
    - Organize tasks into projects with todos for each project following how it is done for personal tasks
    - Generally organize personal wiki through scratch buffers
  - **People**
    - organize meeting notes and general things people are known for

#### Windows

- PowerToys
  - Keyboard Manager
    - Remap Caps Lock -> Esc
    - Remap <C-Shift-Caps Lock> -> Caps Lock
  - Powertoys Run: Win + Space for open
- Msys2
  - C++ (MinGW) / Add to path (C:/msys64/mingw64/bin)
  - WSL

#### Arch Linux

##### User Setup

- `useradd -m -G wheel oscar`
- `passwd root` / `passwd oscar` to set some passwords
- `EDITOR=vim visudo` and uncomment out `%wheel ALL=(ALL) ALL` to give wheel user group sudo permissions with password

##### WSL Setup (if applicable)

```bash
wsl --set-default archlinux # default distro
wsl --manage archlinux --set-default-user oscar # set default user (might need to update wsl)
```

##### Use This Repo

- `pacman -S git sudo` to pull and use setup scripts
