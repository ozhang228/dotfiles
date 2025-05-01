---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
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
      },
    },
  },
}
