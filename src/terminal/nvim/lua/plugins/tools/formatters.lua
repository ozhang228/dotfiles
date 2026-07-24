local oxfmt_config_files = {
  ".oxfmtrc.json",
  ".oxfmtrc.jsonc",
  "oxfmt.config.ts",
  "oxfmt.config.mts",
}

local function oxc_formatters() return { "oxfmt", "prettierd", "prettier", stop_after_first = true } end

local function oxfmt_root(_, ctx) return vim.fs.root(ctx.dirname, oxfmt_config_files) end

return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      typescript = oxc_formatters(),
      javascript = oxc_formatters(),
      typescriptreact = oxc_formatters(),
      javascriptreact = oxc_formatters(),
      html = oxc_formatters(),
      css = oxc_formatters(),
      python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      lua = { "stylua" },
      rust = { "rustfmt" },
      -- Misc
      json = oxc_formatters(),
      markdown = oxc_formatters(),
      mdx = oxc_formatters(),
      astro = { "prettierd", "prettier", stop_after_first = true },
    },
    formatters = {
      oxfmt = {
        cwd = oxfmt_root,
        require_cwd = true,
      },
    },
    format_on_save = function(bufnr)
      local path = vim.api.nvim_buf_get_name(bufnr)
      if vim.bo[bufnr].filetype == "markdown" and not path:match("/forge/") then return nil end
      return {
        timeout_ms = 500,
        lsp_format = "fallback",
      }
    end,
  },
}
