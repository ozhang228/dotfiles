return {
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    library = {
      { path = "vimruntime", words = { "vim" } },
      { path = "luvit-meta/library", words = { "vim%.uv" } },
    },
  },
}
