vim.o.mouse = "a"
vim.cmd.colorscheme("rose-pine")
vim.o.shell = "/bin/fish"

vim.g.have_nerd_font = true

local function command_output(cmd)
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then return nil end
  return vim.trim(result.stdout)
end

local function tmux_client_value(format)
  if not vim.env.TMUX then return nil end
  return command_output({ "tmux", "display-message", "-p", format })
end

local function tmux_client_supports_clipboard()
  local termfeatures = tmux_client_value("#{client_termfeatures}")
  return termfeatures ~= nil and termfeatures:find("clipboard", 1, true) ~= nil
end

local function tmux_client_is_ssh()
  local client_pid = tmux_client_value("#{client_pid}")
  if client_pid == nil or client_pid == "" then return false end
  local parent_pid = command_output({ "ps", "-o", "ppid=", "-p", client_pid })
  if parent_pid == nil or parent_pid == "" then return false end
  local parent_command = command_output({ "ps", "-o", "comm=", "-p", parent_pid })
  return parent_command == "sshd"
end

local function cached_osc52_provider()
  local osc52 = require("vim.ui.clipboard.osc52")
  local cached_registers = {
    ["+"] = { lines = {}, regtype = "v" },
    ["*"] = { lines = {}, regtype = "v" },
  }

  local function copy(reg)
    local osc52_copy = osc52.copy(reg)
    return function(lines, regtype)
      cached_registers[reg] = { lines = lines, regtype = regtype }
      osc52_copy(lines, regtype)
    end
  end

  local function paste(reg)
    return function()
      local cached_register = cached_registers[reg]
      return { cached_register.lines, cached_register.regtype }
    end
  end

  return {
    name = "OSC 52",
    copy = {
      ["+"] = copy("+"),
      ["*"] = copy("*"),
    },
    paste = {
      ["+"] = paste("+"),
      ["*"] = paste("*"),
    },
  }
end

vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = true

-- Sync clipboard between OS and Neovim.
-- Over SSH, use OSC 52 so yanks land in the terminal emulator's clipboard.
-- In a reattached tmux pane, SSH_TTY may be absent even though the active
-- SSH client supports terminal clipboard operations.
-- Locally, fall through to the default provider (xclip/wl-copy) — OSC 52
-- paste triggers a per-paste permission prompt in most terminals.
-- See `:help 'clipboard'`
if vim.env.SSH_TTY or (tmux_client_is_ssh() and tmux_client_supports_clipboard()) then vim.g.clipboard = cached_osc52_provider() end
vim.schedule(function() vim.o.clipboard = "unnamedplus" end)

local default_open = vim.ui.open
vim.ui.open = function(path, opt)
  if (vim.env.SSH_TTY or tmux_client_is_ssh()) and path:match("^%a[%w+.-]*://") then
    require("vim.ui.clipboard.osc52").copy("+")({ path })
    vim.api.nvim_echo({ { "URL copied to the SSH client clipboard" } }, false, {})
    return nil, nil
  end
  return default_open(path, opt)
end

-- A wrapped line will have same indent on every line
vim.o.breakindent = true

-- Store an undo file so undos persist through sessions
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or 1+ capital letters in the search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn (gutters) on by default
vim.o.signcolumn = "yes"

-- Decrease update time for better responsivenes in plugins
vim.o.updatetime = 250

-- Decrease mapped sequence wait time (makes mappings feel faster)
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
vim.o.list = true
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Highlights which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- 24-bit color for nvim-notify
vim.opt.termguicolors = true

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- what to save in a session
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- never show the tabline; we don't use tabs as a workflow primitive
vim.o.showtabline = 0

vim.o.swapfile = false
vim.o.linebreak = true
