return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
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
