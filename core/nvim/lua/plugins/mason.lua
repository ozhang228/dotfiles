---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        -- Core Languages: HTML/CSS/JS/TS, Python, C++, OCaml --
        -- HTML/CSS/JS
        "vtsls",
        "html-lsp",
        "emmet-language-server",
        "eslint-lsp",
        "prettier",
        -- C/C++
        "clangd",
        -- Python
        "ruff",
        "pyrefly",
        -- OCaml
        "ocaml-lsp",
        -- Misc
        "tree-sitter-cli",
        "stylua",
        "lua-language-server",
      },
    },
  },
}
