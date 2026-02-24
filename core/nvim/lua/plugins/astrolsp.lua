return {
  {
    "AstroNvim/astrolsp",
    opts = {
      features = {
        codelens = true,
        inlay_hints = false,
        semantic_tokens = true,
      },
      formatting = {
        format_on_save = {
          enabled = true,
          ignore_filetypes = { "markdown", "text" },
          lsp_fallback = false,
        },
        disabled = {
          "eslint",
        },
        timeout_ms = 2000,
      },
      config = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                autoImportCompletions = true,
                useLibraryCodeForTypes = true,
                disableOrganizeImports = true,
                typeCheckingMode = "standard",
              },
            },
            python = {
              venvPath = vim.fn.expand "~/drw/desk-tools/python",
              venv = ".venv",
            },
          },
        },
        ruff = {
          on_attach = function(client, _)
            client.server_capabilities.hoverProvider = false
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
            client.server_capabilities.codeActionProvider = false
          end,
        },
        clangd = {
          cmd = {
            "clangd",
            "--fallback-style=Google",
          },
        },
      },
      handlers = {},
      autocmds = {},
      mappings = {
        n = {},
      },
      on_attach = function(client, bufnr) end,
    },
  },
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local null_ls = require "null-ls"

      opts.sources = {
        null_ls.builtins.diagnostics.mypy.with {
          extra_args = { "--ignore-missing-imports" },
        },
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
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "typescript",
        "javascript",
        "python",
        "lua",
        "cpp",
        "java",
      },
      highlight = {
        enable = true,
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        -- TS/JS
        "eslint-lsp",
        "prettierd",
        "vtsls",
        -- C/C++
        "clangd",
        -- Python
        "basedpyright",
        "ruff",
        "mypy",
        -- Misc
        "tree-sitter-cli",
        "stylua",
        "lua-language-server",
      },
    },
  },
}
