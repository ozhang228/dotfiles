return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "folke/snacks.nvim",
  },
  opts = {
    picker = "snacks",
    enable_builtin = true,
    mappings_disable_default = true,
  },
}
