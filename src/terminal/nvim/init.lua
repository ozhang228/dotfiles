-- :help mapleader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("plugin_manager")
require("options")
require("keymaps")
require("autocmds")
require("lsp")
require("globals")

vim.diagnostic.config({
  update_in_insert = false,
  severity_sort = true,
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = {
    spacing = 4,
    prefix = "●",
    severity = { min = vim.diagnostic.severity.WARN },
    format = function(d) return string.format("[%s] %s", d.source, d.message) end,
  },
  float = {
    focusable = true,
    style = "minimal",
    border = "rounded",
    format = function(d) return string.format("[%s] %s", d.source, d.message) end,
  },
  signs = true,
})
