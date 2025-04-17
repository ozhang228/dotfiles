---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.utility.noice-nvim" },
  { import = "astrocommunity.programming-language-support.rest-nvim" },
  { import = "astrocommunity.bars-and-lines.lualine-nvim" },

  -- language packs
  { import = "astrocommunity.pack.java" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.markdown" },

  -- import/override with your plugins folder
}
