return {
  "obsidian-nvim/obsidian.nvim",
  -- TODO: pinned because obsidian-lsp document symbols issue, when this gets fixed, unpin
  version = "3.10.0",
  ft = "markdown",
  dependencies = {
    "Saghen/blink.cmp",
    "folke/snacks.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "Notes",
        path = "$HOME/notes",
      },
    },
    completion = {
      blink = true,
      nvim_cmp = false,
    },
    ui = {
      enable = false,
    },
    open = {
      use_advanced_uri = true,
    },
    finder = "snacks.pick",
    follow_url_func = vim.ui.open,
    legacy_commands = false,
  },
}
