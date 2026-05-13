return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      -- TS/JS
      "typescript",
      "javascript",
      "tsx",

      -- Python
      "python",

      -- C/C++
      "c",
      "cpp",

      -- Lua
      "lua",
      "luadoc",

      -- Misc
      "html",
      "css",
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
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
    vim.treesitter.language.register("markdown", "octo")
  end,
}
