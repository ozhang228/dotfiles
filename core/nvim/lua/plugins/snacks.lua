return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    picker = {
      enabled = true,
      hidden = true,
      win = {
        list = {
          wo = {
            relativenumber = true,
          },
        },
      },
      sources = {
        noice = {
          confirm = { "yank", "close" },
        },
      },
    },
    notifer = {
      enabled = true,
      style = "compact",
      top_down = "false",
    },
    scratch = {
      enabled = false,
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
    lazygit = {
      enabled = true,
    },
    dashboard = {
      preset = {
        header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
      },
      sections = {
        {
          section = "terminal",
          cmd = "cat ~/dotfiles/imgs/charizard_ascii.txt; sleep .1",
          height = 22,
          padding = 1,
          indent = 6,
        },
        { section = "header" },
      },
    },
  },
  keys = {},
}
