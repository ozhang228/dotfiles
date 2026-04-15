return {
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      auto_update = true,
      ensure_installed = {
        -- TS/JS
        "tsgo",
        "vtsls",
        "eslint_d",

        "prettierd",
        "prettier",

        -- Python
        "basedpyright",
        "ty",
        "ruff",

        -- C/C++
        "clangd",
        "clang-format",
        "codelldb",

        -- Lua
        "lua-language-server",
        "luacheck",
        "stylua",

        -- Go
        "gopls",
        "golangci-lint",

        -- Misc
        "jq",
        "checkmake",
        "taplo",
      },
    },
  },
}
