return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "typescript",
      "javascript",
      "tsx",
      "html",
      "css",

      "python",

      "c",
      "cpp",

      "lua",
      "luadoc",

      "rust",

      -- Misc
      "json",
      "yaml",
      "vimdoc",
      "markdown",
      "markdown_inline",
      "query",
      "regex",
      "toml",
    },
    highlight = {
      enable = true,
    },
    indent = {
      enable = true,
    },
  },
  build = ":TSUpdate",
}
