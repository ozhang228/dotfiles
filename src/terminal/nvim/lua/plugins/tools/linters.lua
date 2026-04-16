return {
  "mfussenegger/nvim-lint",
  config = function()
    local lint = require("lint")

    lint.linters.ty = {
      name = "ty",
      cmd = "ty",
      stdin = false,
      append_fname = true,
      args = { "check", "--output-format", "concise" },
      stream = "stdout",
      ignore_exitcode = true,
      parser = function(output)
        local diagnostics = {}
        local severity_map = {
          error = vim.diagnostic.severity.ERROR,
          warning = vim.diagnostic.severity.WARN,
          info = vim.diagnostic.severity.INFO,
          hint = vim.diagnostic.severity.HINT,
        }

        -- concise format: path/to/file.py:line:col: severity[code] message
        local pattern = "^[^:]+:(%d+):(%d+):%s+(%a+)%[([^%]]+)%]%s+(.+)$"

        for line in output:gmatch("[^\n]+") do
          local row, col, severity_str, code, message = line:match(pattern)

          if row and col and severity_str and message then
            table.insert(diagnostics, {
              lnum = tonumber(row) - 1,
              col = tonumber(col) - 1,
              severity = severity_map[severity_str] or vim.diagnostic.severity.ERROR,
              message = message,
              code = code,
              source = "ty",
            })
          end
        end

        return diagnostics
      end,
    }

    lint.linters_by_ft = {
      -- TS/JS
      typescript = { "eslint_d" },
      javascript = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      html = { "eslint_d" },
      css = { "eslint_d" },

      -- C / C++
      c = { "clang-tidy" },
      cpp = { "clang-tidy" },

      -- Python
      python = { "ty", "ruff" },

      -- Lua
      lua = { "luacheck" },

      -- Go
      go = { "golangcilint" },

      -- Misc
      json = { "eslint_d" },
      makefile = { "checkmake" },
    }
  end,
}
