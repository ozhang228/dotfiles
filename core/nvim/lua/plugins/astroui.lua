return {
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = {
      colorscheme = "catppuccin-mocha",
      icons = {
        LSPLoading1 = "⠋",
        LSPLoading2 = "⠙",
        LSPLoading3 = "⠹",
        LSPLoading4 = "⠸",
        LSPLoading5 = "⠼",
        LSPLoading6 = "⠴",
        LSPLoading7 = "⠦",
        LSPLoading8 = "⠧",
        LSPLoading9 = "⠇",
        LSPLoading10 = "⠏",
      },
    },
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      styles = {
        comments = { "italic" },
        functions = { "bold" },
        keywords = { "italic" },
        operators = { "bold" },
        conditionals = { "bold" },
        loops = { "bold" },
        booleans = { "bold", "italic" },
        numbers = {},
        types = {},
        strings = {},
        variables = {},
        properties = {},
      },
      highlight_overrides = {
        all = function(cp)
          return {
            LineNr = { fg = cp.blue },
            -- for directories in picker
            NonText = { fg = cp.overlay2 },
          }
        end,
      },
      transparent_background = true,
      float = {
        transparent = true,
      },
    },
  },
  {
    "rebelot/heirline.nvim",
    -- turn off for lualine
    opts = {
      statusline = nil,
    },
  },
  {
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
  },
}
