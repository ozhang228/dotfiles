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
        "tsgo",
        "vtsls",
        "eslint_d",

        "prettierd",
        "prettier",

        "basedpyright",
        "ty",
        "ruff",

        "clangd",
        "clang-format",
        "codelldb",

        "lua-language-server",
        "luacheck",
        "stylua",

        "rust-analyzer",

        "jq",
        "checkmake",
        "marksman",
      },
    },
  },
}
