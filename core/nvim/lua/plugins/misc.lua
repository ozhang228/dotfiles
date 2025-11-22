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
}
