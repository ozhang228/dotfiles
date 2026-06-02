return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  config = function()
    vim.schedule(
      function()
        require("nvim-treesitter").install({
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
          "json",
          "yaml",
          "vim",
          "vimdoc",
          "markdown",
          "markdown_inline",
          "query",
          "regex",
          "toml",
        })
      end
    )
  end,
}
