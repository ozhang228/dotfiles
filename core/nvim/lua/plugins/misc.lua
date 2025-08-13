return {
  {
    "mistweaverco/kulala.nvim",
    opts = {
      ui = {
        show_icons = "above_request",
        formatter = true,
        display_mode = "float",
        winbar = false,
      },
    },
    ft = { "http" },
  },
  {
    "stevearc/oil.nvim",
    opts = {
      view_options = {
        show_hidden = true,
        is_hidden_file = function(name, _)
          local m = name:match "^%."
          return m ~= nil
        end,
        natural_order = "fast",
        case_insensitive = false,
        sort = {
          { "type", "asc" },
          { "name", "asc" },
        },
      },
      watch_for_changes = false,
      delete_to_trash = true,
      lsp_file_methods = {
        enabled = true,
      },
    },
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    lazy = false,
  },
  {
    "folke/noice.nvim",
    opts = {
      presets = { bottom_search = false },
    },
  },
  { -- better quickfix list
    "kevinhwang91/nvim-bqf",
    opts = {},
  },
  { -- docstrings
    "danymat/neogen",
    opts = {},
  },

  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      start_in_insert = true,
      persist_mode = false,
      auto_scroll = false,
      float_opts = {
        border = "curved",
      },
    },
  },
}
