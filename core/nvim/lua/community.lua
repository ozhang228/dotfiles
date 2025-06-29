---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.utility.noice-nvim" },
  { import = "astrocommunity.bars-and-lines.lualine-nvim" },

  -- language packs
  { import = "astrocommunity.pack.java" },
  { import = "astrocommunity.pack.typescript" },
}
