return {
  "folke/snacks.nvim",
  opts = {
    scratch = {
      enabled = true,
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
