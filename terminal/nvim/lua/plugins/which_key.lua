return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    sort = { "manual" },
    layout = {
      spacing = 1,
    },
    icons = {
      mappings = false, -- no icons on mapping
      group = "",
    },
    delay = 50, -- faster
  },
}
