---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "vtsls",
        "html-lsp",
        "emmet-language-server",
        "eslint-lsp",
        "jdtls",
        "clangd",
        "stylua",
        "prettier",
        "ruff",
      },
    },
  },
}
