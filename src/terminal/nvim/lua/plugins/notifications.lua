return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    styles = {
      float = { backdrop = false, wo = { winblend = 0 } },
      notification = { wo = { winblend = 0 } },
    },
    notifier = { enabled = true, style = "compact" },
  },
}
