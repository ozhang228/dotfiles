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
      env = { LAZYGIT_NEW_DIR_FILE = vim.fn.expand "~/.lazygit/newdir" },
      win = {
        on_close = function()
          local f = vim.fn.expand "~/.lazygit/newdir"
          if vim.fn.filereadable(f) == 1 then
            local new_root = vim.fn.readfile(f)[1]
            os.remove(f)
            if new_root and new_root ~= "" then
              local old_cwd = vim.fn.getcwd()
              local git_root =
                vim.fn.systemlist("git -C " .. vim.fn.shellescape(old_cwd) .. " rev-parse --show-toplevel")[1]
              local rel = ""
              if git_root and old_cwd:find(git_root, 1, true) == 1 then rel = old_cwd:sub(#git_root + 2) end
              local target = rel ~= "" and (new_root .. "/" .. rel) or new_root
              if vim.fn.isdirectory(target) == 1 then
                vim.cmd.cd(target)
              else
                vim.cmd.cd(new_root)
              end
              -- Write final cwd for shell wrapper to pick up on nvim exit
              vim.fn.writefile({ vim.fn.getcwd() }, vim.fn.expand "~/.nvim_newdir")
            end
          end
        end,
      },
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
        { section = "header" },
        {
          section = "terminal",
          cmd = "cat ~/dotfiles/imgs/corviknight_ascii.txt; sleep .1",
          height = 22,
          padding = 1,
          indent = 6,
        },
      },
    },
  },
  keys = {},
}
