local palette = require("theme_palette")

local function mode_theme(mode_bg)
  return {
    a = { fg = palette.bg, bg = mode_bg, gui = "bold" },
    b = { fg = palette.fg, bg = palette.bg_alt },
    c = { fg = palette.fg, bg = palette.bg },
  }
end

local theme = {
  normal = mode_theme(palette.fg_muted),
  insert = mode_theme(palette.accent),
  visual = mode_theme(palette.orange),
  replace = mode_theme(palette.red),
  command = mode_theme(palette.purple),
  terminal = mode_theme(palette.green),
  inactive = {
    a = { fg = palette.fg_muted, bg = palette.bg_alt },
    b = { fg = palette.fg_muted, bg = palette.bg_alt },
    c = { fg = palette.fg_muted, bg = palette.bg_alt },
  },
}

return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = { theme = theme },
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
