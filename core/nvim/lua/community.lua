---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.utility.noice-nvim" },
  { import = "astrocommunity.markdown-and-latex.render-markdown-nvim" },

  -- language packs
  { import = "astrocommunity.pack.java" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.markdown" },

  -- import/override with your plugins folder
}
