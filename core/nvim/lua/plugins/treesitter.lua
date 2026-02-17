---@type LazySpec

return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "typescript",
      "javascript",
      "python",
      "lua",
      "cpp",
      "java",
    },
    highlight = {
      enable = true,
    },
  },
}
