---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        -- install language servers
        "lua-language-server",
        "vtsls",
        "html-lsp",
        "emmet-language-server",
        "eslint-lsp",
        "jdtls",
        "clangd",
        "json-lsp",

        -- install formatters
        "stylua",
        "prettier",
        "ruff",
      },
    },
  },
}
