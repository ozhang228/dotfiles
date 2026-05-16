return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    terminal = {
      enabled = true,
      win = {
        style = "float",
        border = "none",
        width = 0.99,
        height = 0.99,
        keys = {
          term_normal = {
            "<leader><esc>",
            function(self) vim.cmd("stopinsert") end,
            mode = "t",
            desc = "Exit to normal mode",
          },
        },
      },
    },
  },
}
