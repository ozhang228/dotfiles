return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
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
  },
}
