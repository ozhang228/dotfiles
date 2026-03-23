return {
  {
    "Saghen/blink.cmp",
    version = "1.*", -- prebuilt binaries for fuzzy
    dependencies = {
      "mikavilpas/blink-ripgrep.nvim",
    },
    opts = {
      enabled = function()
        if vim.bo[0].filetype == "snacks_picker_input" then return false end
        return true
      end,
      appearance = {
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lazydev", "lsp", "ripgrep", "snippets", "path", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 15,
          },
          lsp = {
            score_offset = 10,
          },
          snippets = {
            score_offset = 5,
            min_keyword_length = 2,
          },
          path = {
            score_offset = 3,
            opts = {
              show_hidden_files_by_default = true,
            },
          },
          ripgrep = {
            module = "blink-ripgrep",
            name = "Ripgrep",
            score_offset = 1,
            opts = {
              prefix_min_len = 4,
              backend = {
                use = "gitgrep-or-ripgrep",
                max_filesize = "200K",
              },
            },
          },
          buffer = {
            score_offset = 0,
            min_keyword_length = 4,
            max_items = 10,
          },
        },
      },
      completion = {
        accept = {
          auto_brackets = { enabled = true },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 100,
        },
        menu = {
          border = "rounded",
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "kind_icon", gap = 1 },
              { "label", "label_description", gap = 3 },
              { "kind", "source_name", gap = 2 },
            },
            components = {
              kind_icon = {
                text = function(ctx)
                  local icon = ctx.kind_icon
                  if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                    if dev_icon then icon = dev_icon end
                  end
                  return icon .. ctx.icon_gap
                end,
                highlight = function(ctx)
                  if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local _, hl = require("nvim-web-devicons").get_icon(ctx.label)
                    if hl then return hl end
                  end
                  return "BlinkCmpKind" .. ctx.kind
                end,
              },
              source_name = {
                text = function(ctx) return "[" .. ctx.source_name .. "]" end,
                highlight = "BlinkCmpSource",
              },
            },
          },
        },
      },
      signature = { enabled = true },
      fuzzy = { implementation = "prefer_rust" },
    },
    documentation = {
      window = { border = "rounded" },
    },
  },
}
