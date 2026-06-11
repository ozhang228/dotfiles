return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      typescript = { "prettierd", "prettier", stop_after_first = true },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd", "prettier", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },
      python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      lua = { "stylua" },
      rust = { "rustfmt" },
      -- Misc
      json = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
    },
    format_on_save = function(bufnr)
      local path = vim.api.nvim_buf_get_name(bufnr)
      if vim.bo[bufnr].filetype == "markdown" and not path:match("/forge/") then
        return nil
      end
      return {
        timeout_ms = 500,
        lsp_format = "fallback",
      }
    end,
  },
}
