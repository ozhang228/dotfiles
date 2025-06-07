if vim.fn.has "win32" == 1 then
  return {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "Saghen/blink.cmp",
      "folke/snacks.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "Career Notes",
          path = "G:/My Drive/Career Notes",
        },
        {
          name = "Archive",
          path = "G:/My Drive/Archive",
        },
      },
      completion = {
        blink = true,
        nvim_cmp = false,
      },
      ui = {
        enable = false,
      },
    },
  }
else
  return {}
end
