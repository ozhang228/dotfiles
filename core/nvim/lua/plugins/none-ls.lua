return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require "null-ls"

    opts.sources = {
      null_ls.builtins.formatting.prettierd.with {
        filetypes = {
          "typescript",
          "typescriptreact",
          "javascript",
          "javascriptreact",
          "json",
          "css",
          "html",
        },
      },
      require("null-ls.helpers").make_builtin {
        name = "ruff_format",
        method = null_ls.methods.FORMATTING,
        filetypes = { "python" },
        generator_opts = {
          command = "ruff",
          args = { "format", "--stdin-filename", "$FILENAME", "-" },
          to_stdin = true,
        },
        factory = require("null-ls.helpers").formatter_factory,
      },
      require("null-ls.helpers").make_builtin {
        name = "ruff_fix",
        method = null_ls.methods.FORMATTING,
        filetypes = { "python" },
        generator_opts = {
          command = "ruff",
          args = { "check", "--fix", "--exit-zero", "--stdin-filename", "$FILENAME", "-" },
          to_stdin = true,
        },
        factory = require("null-ls.helpers").formatter_factory,
      },
    }

    return opts
  end,
}
