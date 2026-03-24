return {
  "mfussenegger/nvim-lint",
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      -- TS/JS
      typescript = { "eslint_d" },
      javascript = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      html = { "eslint_d" },
      css = { "eslint_d" },

      -- Python
      python = { "ty", "ruff" },

      -- Lua
      lua = { "luacheck" },

      -- Misc
      json = { "eslint_d" },
      makefile = { "checkmake" },
    }
  end,
}
