return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    lsp = {
      rename = {
        enabled = true,
      },
    },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
}
