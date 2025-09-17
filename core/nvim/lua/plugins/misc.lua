return {
  {
    "mistweaverco/kulala.nvim",
    opts = {
      ui = {
        show_icons = "above_request",
        formatter = true,
        display_mode = "float",
        winbar = false,
      },
    },
    ft = { "http" },
  },
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
  { -- docstrings
    "danymat/neogen",
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
}
