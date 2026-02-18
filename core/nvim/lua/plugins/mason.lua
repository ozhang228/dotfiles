---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        -- TS/JS
        "vtsls",
        "eslint-lsp",
        "prettierd",
        -- C/C++
        "clangd",
        -- Python
        "basedpyright",
        "ruff",
        -- Misc
        "tree-sitter-cli",
        "stylua",
        "lua-language-server",
      },
    },
  },
}
