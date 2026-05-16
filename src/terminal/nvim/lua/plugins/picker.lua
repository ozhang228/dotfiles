return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    picker = {
      enabled = true,
      hidden = true,
      win = {
        list = {
          wo = {
            relativenumber = true,
          },
        },
      },
      formatters = {
        file = {
          filename_first = true,
        },
      },
      jump = {
        jumplist = false,
      },
    },
  },
}
