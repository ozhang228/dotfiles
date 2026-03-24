return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      enabled = true,
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
