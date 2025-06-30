return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    picker = {
      enabled = true,
      hidden = true,
    },
    notifer = {
      enabled = true,
      style = "compact",
      top_down = "false",
    },
    scratch = {
      enabled = true,
      filekey = {
        cwd = true,
        count = false,
        branch = false,
      },
    },
    bigfile = {
      enabled = true,
    },
    quickfile = {
      enabled = true,
    },
    indent = {
      enabled = true,
      current_scope = true,
      indent = {
        enabled = false,
      },
      chunk = {
        enabled = true,
        char = {
          corner_top = "╭",
          corner_bottom = "╰",
          horizontal = "─",
          vertical = "│",
          arrow = ">",
        },
      },
    },
  },
  keys = {},
}
