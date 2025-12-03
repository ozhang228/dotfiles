return {
  "AstroNvim/astrocore",
  opts = {
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 },
      autopairs = true,
      cmp = true,
      diagnostics_mode = 3,
      highlighturl = true,
      notifications = true,
    },
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    options = {
      opt = {
        relativenumber = true,
        number = true,
        spell = false,
        signcolumn = "yes",
        wrap = true,
        conceallevel = 0,
        swapfile = false,
      },
    },
    autocmds = {},
    mappings = {
      n = {
        ["<Leader>fr"] = {
          function() require("snacks.picker").lsp_references() end,
          nowait = true,
          desc = "Find references",
        },
        ["<Leader>o"] = {
          function()
            require("mini.files").open(vim.api.nvim_buf_get_name(0), false)
            require("mini.files").reveal_cwd()
          end,
          desc = "Open Mini.files",
        },
        ["<Leader>x"] = {
          desc = require("mini.icons").get("filetype", "Trouble") .. " QFL",
        },

        ["<Leader>t1"] = {
          "<CMD>ToggleTerm1 direction=float<CR>",
          desc = "ToggleTerm1",
        },
        ["<Leader>t2"] = {
          "<CMD>ToggleTerm2 direction=float<CR>",
          desc = "ToggleTerm2",
        },
        ["<Leader>t3"] = {
          "<CMD>ToggleTerm3 direction=float<CR>",
          desc = "ToggleTerm3",
        },
        ["<Leader>t4"] = {
          "<CMD>ToggleTerm4 direction=float<CR>",
          desc = "ToggleTerm4",
        },
        ["<Leader>t5"] = {
          "<CMD>ToggleTerm5 direction=float<CR>",
          desc = "ToggleTerm5",
        },

        ["<Leader>gg"] = {
          function() require("snacks").lazygit() end,
          desc = "Open LazyGit",
        },
        ["<Leader>gi"] = {
          function() require("snacks").picker.gh_issue() end,
          desc = "Github Issues",
        },
        ["<Leader>gp"] = {
          function() require("snacks").picker.gh_pr() end,
          desc = "Github Pull Requests",
        },

        ["<Leader>ta"] = {
          function()
            local cmd = vim.fn.getenv "AI_CLI_CMD"

            if cmd == nil or cmd == "" then
              vim.notify("AI_CLI_CMD is not set in your shell environment.", vim.log.levels.ERROR)
              return
            end

            local term = require("toggleterm.terminal").Terminal:new {
              cmd = cmd,
              direction = "float",
              hidden = false,
              close_on_exit = false,
              -- to prevent it from colliding with my terminals
              id = 100,
            }

            term:toggle()
          end,
          desc = "Open AI CLI",
        },

        ["n"] = {
          [[nzz]],
          desc = "Next search result with cursor centered",
        },
        ["N"] = {
          [[Nzz]],
          desc = "Previous search result with cursor centered",
        },
        ["<C-D>"] = {
          [[<C-D>zz]],
          desc = "Scroll down with cursor centered",
        },
        ["<C-U>"] = {
          [[<C-U>zz]],
          desc = "Scroll up with cursor centered",
        },
        ["<Leader>fm"] = {
          function()
            vim.ui.input({ prompt = "Manual page for: " }, function(input)
              if input and input ~= "" then vim.cmd("vert Man " .. input) end
            end)
          end,
          desc = "Find man page",
        },
        ["<Leader>lI"] = {
          "<CMD>Conform<CR>",
          desc = "Conform formatter information",
        },
        ["<Leader>W"] = {
          ":noa w<CR>",
          desc = "Save without formatting",
        },

        ["s"] = false,
        ["S"] = false,
        ["<Leader>n"] = false,
        ["<Leader>R"] = false,
        ["<Leader>C"] = false,
        ["<Leader>gc"] = false,
        ["<Leader>gC"] = false,
        ["<Leader>gT"] = false,
        ["<Leader>h"] = false,
        ["<Leader>d"] = false,
        ["<Leader>tf"] = false,
        ["<Leader>th"] = false,
        ["<Leader>tp"] = false,
        ["<Leader>tv"] = false,
        ["<Leader>ts"] = false,
      },

      t = {
        ["<Esc><Esc>"] = [[<C-\><C-n>]],
      },
      i = {
        ["<Tab>"] = "<Tab>",
      },
      c = {
        ["<Tab>"] = "<Tab>",
      },
    },
  },
}
