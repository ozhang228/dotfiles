# Symlinks + Package Install

## Supported

### Distributions

- **Windows**
- **Mac**
- **Ubuntu**

### Languages (by default)

- Python (pip / uv)
- JavaScript (Node.js / npm)
- C++ (gcc)
  - Windows needs to do it manually

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

### Distribution Specific

#### Windows

- [Powershell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5)
  - [PSReadLine](https://github.com/PowerShell/PSReadLine)
  - [PowerShellget](https://learn.microsoft.com/en-us/powershell/gallery/powershellget/install-powershellget?view=powershellget-3.x)
  - [PSFzf](https://github.com/kelleyma49/PSFzf.git)
- [GlazeWM](https://github.com/glzr-io/glazewm)

#### Ubuntu

- [build-essentials](https://packages.debian.org/sid/build-essential): C++ compilers
- [luarocks](https://innovativeinnovation.github.io/ubuntu-setup/lua/luarocks.html): necessary for rest-client in nvim and doesn't autoinstall in Ubuntu
- [curl](https://curl.se/download.html): call APIs

### Manual Setup

- Notion
  - **To-Do List & Project Management**
    - Organize tasks into projects with todos for each project following how it is done for personal tasks
    - Generally organize personal wiki through scratch buffers
  - **People**
    - organize meeting notes and general things people are known for
- [Desktop Background](https://drive.google.com/drive/folders/1AR-AnlCRXYyG7CBdxvlHCFGqA6IRxXQi)
- Set terminal font to downloaded JetBrains Mono Font
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
