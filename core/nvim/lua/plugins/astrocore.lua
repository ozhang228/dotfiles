---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
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
        conceallevel = 2,
      },
    },
    autocmds = {
      format = {},
    },
    mappings = {
      n = {
        -- File Utils
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
        -- END File Utils

        ["<Leader>ls"] = {
          [[<CMD>Neogen<CR>]],
          desc = "Generate docstring",
        },

        -- Terminal
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
        -- END Terminal

        -- Grapple (used to be harpoon)
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
        -- END Grapple

        -- Kulala Rest Client
        ["<Leader>r"] = {
          "Nop",
          desc = require("mini.icons").get("lsp", "file") .. " Kulala Rest Client",
        },
        ["<Leader>rr"] = {
          function() require("kulala").run() end,
          desc = "Run http request",
        },
        -- END Kulala Rest Client

        -- Scratch
        ["<Leader>s"] = {
          desc = require("mini.icons").get("filetype", "Scratch") .. " Scratch",
        },
        ["<Leader>sh"] = {
          function() require("snacks").scratch.open { ft = "http" } end,
          desc = "Open HTTP scratch buffer",
        },
        ["<Leader>sm"] = {
          function() require("snacks").scratch.open { ft = "markdown" } end,
          desc = "Open markdown scratch buffer",
        },
        -- END Scratch

        -- Git
        ["<Leader>gt"] = false,
        ["<Leader>gb"] = false,
        ["<Leader>gc"] = false,
        ["<Leader>gC"] = false,
        ["<Leader>gT"] = false,
        -- END Git

        -- Misc
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
        -- Remove these keybinds to delete into register x because I never use it
        ["s"] = { "<nop>" },
        ["S"] = { "<nop>" },
        ["<Leader>fm"] = {
          function()
            vim.ui.input({ prompt = "Manual page for: " }, function(input)
              if input and input ~= "" then vim.cmd("vert Man " .. input) end
            end)
          end,
          desc = "Find man page",
        },
        -- End Misc

        -- Use oil instead
        ["<Leader>n"] = false,
        ["<Leader>R"] = false,
        -- Never used force close buffer
        ["<Leader>C"] = false,
      },

      t = {
        -- terminal escape
        ["<Esc>"] = [[<C-\><C-n>]],
      },
    },
  },
}
