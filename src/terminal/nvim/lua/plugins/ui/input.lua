return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    input = {
      enabled = true,
      win = {
        relative = "editor",
        row = function() return math.floor((vim.o.lines - 3) / 2) end,
        width = 40,
        border = "rounded",
      },
    },
  },
}
