---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        -- HTML/CSS/JS
        "vtsls",
        "html-lsp",
        "emmet-language-server",
        "eslint-lsp",
        "prettier",
        -- C/C++
        "clangd",
        -- Lua
        "stylua",
        "lua-language-server",
        -- Python
        "ruff",
        "pyrefly",
        -- Misc
        "tree-sitter-cli",
      },
    },
  },
}
