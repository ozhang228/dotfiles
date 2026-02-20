return {
  {
    "folke/noice.nvim",
    opts = {
      presets = { bottom_search = false },
    },
  },
  { -- better quickfix list
    "kevinhwang91/nvim-bqf",
    opts = {},
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      start_in_insert = true,
      persist_mode = false,
      auto_scroll = false,
      float_opts = {
        border = "curved",
      },
    },
  },
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
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
      legacy_commands = false,
    },
  },
}
