return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      -- TS/JS
      typescript = { "prettierd", "prettier", stop_after_first = true },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd", "prettier", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },

      -- Python
      python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },

      -- C/C++
      c = { "clang-format" },
      cpp = { "clang-format" },

      -- Lua
      lua = { "stylua" },

      -- Misc
      json = { "jq", "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
      toml = { "taplo" },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
  },
}
