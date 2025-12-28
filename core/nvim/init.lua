-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  vim.api.nvim_echo(
    { { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } },
    true,
    {}
  )
  vim.fn.getchar()
  vim.cmd.quit()
end

-- Dist Specific
if vim.fn.has "macunix" == 1 then
  vim.opt.shell = "/bin/zsh"
elseif vim.fn.has "unix" == 1 then
  vim.opt.shell = "/bin/zsh"
else
  local shell = vim.fn.executable "pwsh" == 1 and "pwsh" or "powershell"
  vim.opt.shell = shell
  vim.opt.shellcmdflag =
    "-ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; "
  vim.opt.shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait"
  vim.opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

-- for ocp-indent (Ocaml)
vim.opt.runtimepath:prepend(vim.fn.expand "~/.opam/ocaml_correct_efficient/share/ocp-indent/vim")

vim.api.nvim_set_option_value("shelltemp", false, {})

require "lazy_setup"
require "polish"
