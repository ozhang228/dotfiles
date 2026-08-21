local palette = require("theme_palette")

return {
  "projekt0n/github-nvim-theme",
  name = "github-theme",
  priority = 1000,
  opts = {
    groups = {
      github_light_high_contrast = {
        ["@lsp.type.variable"] = { fg = palette.fg },
        LineNr = { fg = palette.purple },
        NonText = { fg = palette.fg_subtle },
        FloatBorder = { fg = palette.purple },
        FloatTitle = { fg = palette.yellow, bold = true },
      },
    },
  },
}
