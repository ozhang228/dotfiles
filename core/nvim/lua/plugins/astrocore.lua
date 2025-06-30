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

        ["<Leader>t2"] = {
          desc = "ToggleTerm2",
        },
        ["<Leader>t2f"] = {
          "<CMD>ToggleTerm2 direction=float<CR>",
          desc = "ToggleTerm2 Float",
        },
        ["<Leader>t2h"] = {
          "<CMD>ToggleTerm2 direction=horizontal<CR>",
          desc = "ToggleTerm2 Horizontal",
        },

        ["<Leader>h"] = { "Nop", desc = require("mini.icons").get("filetype", "Harpoon") .. " Grapple" },
        ["<Leader>hm"] = {
          "<CMD>Grapple toggle_tags<CR>",
          desc = "Toggle Grapple Quick Menu",
        },
        ["<Leader>ha"] = {
          "<CMD> Grapple toggle<CR>",
          desc = "Add File",
        },
        ["<Leader>hh"] = {
          "<CMD> Grapple cycle_tags prev<CR>",
          desc = "Go to previous Grapple mark",
        },
        ["<Leader>hl"] = {
          "<CMD> Grapple cycle_tags next<CR>",
          desc = "Go to next Grapple mark",
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
        ["<Leader>gt"] = false,
        ["<Leader>gb"] = false,
        ["<Leader>gc"] = false,
        ["<Leader>gC"] = false,
        ["<Leader>gT"] = false,
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
