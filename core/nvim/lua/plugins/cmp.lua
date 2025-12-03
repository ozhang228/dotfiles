return {
  {
    "Saghen/blink.cmp",
    opts = {
      enabled = function()
        local filetype = vim.bo[0].filetype

        if filetype == "snacks_picker_input" then return false end
        return true
      end,
      sources = {
        providers = {
          snippets = { score_offset = 5 },
          path = { score_offset = 0 },
          lsp = { score_offset = 0 },
          buffer = { score_offset = 0 },
        },
      },
      completion = {
        menu = {
          draw = {
            columns = { { "label", "label_description", gap = 3 }, { "source_name" } },
          },
        },
      },
    },
  },
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.luasnip"(plugin, opts)
      require("luasnip.loaders.from_vscode").lazy_load {
        paths = { vim.fn.stdpath "config" .. "/snippets" },
      }
    end,
  },
}
