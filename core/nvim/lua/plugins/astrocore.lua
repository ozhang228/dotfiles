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
          [[<CMD>Oil<CR>]],
          desc = "Open Oil",
        },
        ["<Leader>x"] = {
          desc = require("mini.icons").get("filetype", "Trouble") .. " QFL",
        },

        ["<Leader>ls"] = {
          [[<CMD>Neogen<CR>]],
          desc = "Generate docstring",
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
        ["<Leader>ts"] = {
          "<CMD>TermSelect<CR>",
          desc = "List terminals",
        },

        ["<Leader>r"] = {
          "Nop",
          desc = require("mini.icons").get("lsp", "file") .. " Kulala Rest Client",
        },
        ["<Leader>rr"] = {
          function() require("kulala").run() end,
          desc = "Run http request",
        },

        ["<Leader>s"] = {
          desc = require("mini.icons").get("filetype", "Scratch") .. " Scratch",
        },
        ["<Leader>sm"] = {
          function() require("snacks").scratch.open { ft = "markdown" } end,
          desc = "Open markdown scratch buffer",
        },

        ["<Leader>gg"] = {
          function() require("snacks").lazygit() end,
          desc = "Open LazyGit",
        },

        ["<Leader>gq"] = {
          "<CMD>GitConflictListQf<CR>",
          desc = "Diff QFList",
        },
        ["<Leader>gt"] = {
          "<CMD>GitConflictChooseTheirs<CR>",
          desc = "Choose theirs",
        },
        ["<Leader>go"] = {
          "<CMD>GitConflictChooseOurs<CR>",
          desc = "Choose ours",
        },
        ["<Leader>gb"] = {
          "<CMD>GitConflictChooseBoth<CR>",
          desc = "Choose ours",
        },
        ["<Leader>gO"] = {
          function() require("snacks").gitbrowse() end,
          desc = "Open git repository",
        },

        ["n"] = {
          [[nzz]],
        },
        ["N"] = {
          [[Nzz]],
        },
        ["<C-D>"] = {
          [[<C-D>zz]],
        },
        ["<C-U>"] = {
          [[<C-U>zz]],
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
