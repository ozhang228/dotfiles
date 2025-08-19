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
      {
        name = "Class",
        path = "$HOME/class",
      },
    },
    completion = {
      blink = true,
      nvim_cmp = false,
    },
    ui = {
      enable = false,
    },
    legacy_commands = false,
  },
}
