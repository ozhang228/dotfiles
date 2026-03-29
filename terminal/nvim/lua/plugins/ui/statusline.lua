return {
  "nvim-lualine/lualine.nvim",
  opts = {
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diagnostics" },
      lualine_c = {
        { "filename" },
        {
          require("noice").api.status.mode.get,
          cond = require("noice").api.status.mode.has,
        },
      },
      lualine_x = { "diff" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
  dependencies = {
    "folke/noice.nvim",
  },
}
