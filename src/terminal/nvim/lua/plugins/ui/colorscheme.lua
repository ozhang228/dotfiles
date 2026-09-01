local palette = require("theme_palette")

return {
  "projekt0n/github-nvim-theme",
  name = "github-theme",
  priority = 1000,
  opts = {
    groups = {
      github_light_high_contrast = {
        ["@lsp.type.variable"] = { fg = palette.fg },
        ["@property.yaml"] = { fg = palette.purple, style = "bold" },
        ["@property.json"] = { fg = palette.purple, style = "bold" },
        ["@property.toml"] = { fg = palette.purple, style = "bold" },
        ["@string.yaml"] = { fg = palette.cyan },
        ["@string.json"] = { fg = palette.cyan },
        ["@string.toml"] = { fg = palette.cyan },
        ["@boolean.yaml"] = { fg = palette.orange, style = "bold" },
        ["@boolean.json"] = { fg = palette.orange, style = "bold" },
        ["@boolean.toml"] = { fg = palette.orange, style = "bold" },
        ["@number.yaml"] = { fg = palette.red },
        ["@number.json"] = { fg = palette.red },
        ["@number.toml"] = { fg = palette.red },
        ["@comment.yaml"] = { fg = palette.fg_subtle, style = "italic" },
        ["@comment.json"] = { fg = palette.fg_subtle, style = "italic" },
        ["@comment.toml"] = { fg = palette.fg_subtle, style = "italic" },
        LineNr = { fg = palette.purple },
        NonText = { fg = palette.fg_subtle },
        FloatBorder = { fg = palette.purple },
        FloatTitle = { fg = palette.yellow, bold = true },
      },
    },
  },
}
