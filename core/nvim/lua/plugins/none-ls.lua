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
    }

    return opts
  end,
}
