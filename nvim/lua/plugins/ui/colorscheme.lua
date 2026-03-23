return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  opts = {
    flavour = "mocha",
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
}
