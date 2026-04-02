return {
  "folke/snacks.nvim",
  opts = {
    scratch = {
      enabled = true,
      ft = "markdown",
      root = vim.fn.expand("~/dotfiles/src/terminal/nvim/scratch"),
      filekey = {
        cwd = true,
        branch = false,
        count = true,
      },
      win = {
        style = "scratch",
        width = 180,
        height = 100,
      },
    },
  },
  keys = {
    { "<leader>S", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
  },
}
