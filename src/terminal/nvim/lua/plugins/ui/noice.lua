return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    views = {
      popup = { win_options = { winblend = 0 } },
      hover = {
        border = { style = "rounded" },
        position = { row = 2, col = 0 },
        win_options = { winblend = 0 },
      },
      mini = { win_options = { winblend = 0 } },
    },
    lsp = {
      rename = {
        enabled = true,
      },
    },
    notify = {
      enabled = false,
    },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
}
