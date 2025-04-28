# Symlinks + Package Install

## Supported

### Distributions

- **Windows**
- **Arch Linux (WSL)**:
- **Mac**: untested but should work
  - no tiling manager but want to try aerospace
- **Ubuntu (WSL)**: Don't really use this anymore but keeping the setup file around

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
- [fastfetch](https://github.com/fastfetch-cli/fastfetch): OS information (currently don't use on windows but could incorporate)

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

### Manual Setup

- Notion
  - **To-Do List & Project Management**
    - Organize tasks into projects with todos for each project following how it is done for personal tasks
    - Generally organize personal wiki through scratch buffers
  - **People**
    - organize meeting notes and general things people are known for
- [Desktop Background](https://drive.google.com/drive/folders/1AR-AnlCRXYyG7CBdxvlHCFGqA6IRxXQi)
- gh auth login to get into GitHub

#### Windows

- PowerToys
  - Remap Caps Lock -> Esc
  - Remap <C-Shift-Caps Lock> -> Caps Lock
  - Powertoys Run: Win + Space for open
- Languages
  - C++
    - MinGW thorugh Msys2 + Add to path (should be something like C:/msys64/mingw64/bin)
- WSL

#### Arch Linux
- Git and sudo through pacman to pull the dotfiles repository
