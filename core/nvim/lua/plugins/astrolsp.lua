return {
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
        "basedpyright",
        "vtsls",
        "eslint",
      },
      timeout_ms = 1000,
    },
    servers = {},
    config = {
      basedpyright = {
        settings = {
          basedpyright = {
            disableOrganizeImports = true, -- Using Ruff
            analysis = {
              typeCheckingMode = "standard",
            },
          },
          python = {
            analysis = {
              ignore = { "*" }, -- Using Ruff
            },
          },
        },
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
}
