local function get_branch_changed_files(base)
  base = base or "main"
  local merge_base = vim.fn.systemlist("git merge-base " .. base .. " HEAD 2>/dev/null")
  if vim.v.shell_error ~= 0 then merge_base = vim.fn.systemlist "git merge-base master HEAD 2>/dev/null" end
  if vim.v.shell_error ~= 0 or #merge_base == 0 then
    vim.notify("Could not determine merge base", vim.log.levels.ERROR)
    return {}
  end

  local files = vim.fn.systemlist("git diff --name-only --diff-filter=ACMR " .. merge_base[1] .. "...HEAD")
  local uncommitted = vim.fn.systemlist "git diff --name-only --diff-filter=ACMR HEAD"
  local staged = vim.fn.systemlist "git diff --name-only --diff-filter=ACMR --cached"

  local seen = {}
  local result = {}
  for _, list in ipairs { files, uncommitted, staged } do
    for _, f in ipairs(list) do
      if not seen[f] and f ~= "" then
        seen[f] = true
        table.insert(result, f)
      end
    end
  end
  return result
end

local function ai_term_size() return math.floor(vim.o.columns * 0.5) end

local function get_ai_terminal()
  local cmd = vim.fn.getenv "AI_CLI_CMD"
  if cmd == nil or cmd == "" then
    vim.notify("AI_CLI_CMD is not set in your shell environment.", vim.log.levels.ERROR)
    return nil
  end

  local Terminal = require("toggleterm.terminal").Terminal
  return Terminal:new {
    cmd = cmd,
    direction = "vertical",
    hidden = false,
    close_on_exit = false,
    id = 100,
  }
end

local function send_to_ai_cli(text)
  local term = get_ai_terminal()
  if not term then return end

  local was_open = term:is_open()
  if not was_open then term:open(ai_term_size()) end

  local delay = was_open and 50 or 500
  vim.defer_fn(function()
    if term.job_id then vim.fn.chansend(term.job_id, text) end
    term:focus()
  end, delay)
end

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
    autocmds = {
      open_last_edit = {
        event = "BufReadPost",
        desc = "Open file at the last position it was edited earlier",
        callback = function()
          local mark = vim.api.nvim_buf_get_mark(0, '"')
          if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then vim.api.nvim_win_set_cursor(0, mark) end
        end,
      },
    },
    mappings = {
      n = {
        ["s"] = false,
        ["S"] = false,
        ["<Leader>n"] = false,
        ["<Leader>R"] = false,
        ["<Leader>C"] = false,
        ["<Leader>gC"] = false,
        ["<Leader>gT"] = false,
        ["<Leader>h"] = false,
        ["<Leader>d"] = false,
        ["<Leader>tf"] = false,
        ["<Leader>th"] = false,
        ["<Leader>tv"] = false,
        ["<Leader>ts"] = false,
        ["<Leader>fr"] = {
          function() require("snacks.picker").lsp_references() end,
          nowait = true,
          desc = "Find references",
        },

        ["<Leader>fb"] = {
          "",
          desc = "Branch changed files",
        },
        ["<Leader>fbf"] = {
          function()
            local files = get_branch_changed_files()
            if #files == 0 then
              vim.notify("No changed files in branch", vim.log.levels.INFO)
              return
            end
            require "snacks.picker" {
              title = "Branch Changed Files",
              items = vim.tbl_map(function(f) return { text = f, file = f } end, files),
              format = "file",
              confirm = function(picker, item)
                picker:close()
                vim.cmd.edit(item.file)
              end,
            }
          end,
          nowait = true,
          desc = "Find branch changed files",
        },

        ["<Leader>fbw"] = {
          function()
            local files = get_branch_changed_files()
            if #files == 0 then
              vim.notify("No changed files in branch", vim.log.levels.INFO)
              return
            end
            require("snacks.picker").grep { dirs = files }
          end,
          nowait = true,
          desc = "Grep in branch changed files",
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

        ["<Leader>gc"] = {
          function()
            require("snacks.picker").git_branches {
              title = "Diffview: compare against branch",
              confirm = function(picker, item)
                picker:close()
                if item then vim.cmd("DiffviewOpen " .. item.branch .. "...HEAD") end
              end,
            }
          end,
          desc = "Diffview PR (current branch vs base)",
        },
        ["<Leader>gm"] = {
          function() vim.cmd "DiffviewOpen" end,
          desc = "Diffview Merge Tool",
        },

        ["<Leader>ta"] = {
          function()
            local term = get_ai_terminal()
            if term then term:toggle(ai_term_size()) end
          end,
          desc = "Toggle AI CLI terminal",
        },
        ["<Leader>tp"] = {
          function()
            local relative = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
            if relative == "" then
              vim.notify("No file in current buffer", vim.log.levels.WARN)
              return
            end
            send_to_ai_cli("@" .. relative)
          end,
          desc = "Send file to AI CLI chat box",
        },
        ["<Leader>tl"] = {
          function()
            local relative = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
            if relative == "" then
              vim.notify("No file in current buffer", vim.log.levels.WARN)
              return
            end
            send_to_ai_cli("@" .. relative .. ":" .. vim.fn.line ".")
          end,
          desc = "Send file:line to AI CLI chat box",
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

        ["dd"] = {
          function()
            if vim.api.nvim_get_current_line():match "^%s*$" then
              return '"_dd'
            else
              return "dd"
            end
          end,
          expr = true,
          desc = "Smart dd (blackhole delete blank lines)",
        },
      },

      v = {
        ["<Leader>tl"] = {
          function()
            local start_line = vim.fn.line "v"
            local end_line = vim.fn.line "."
            if start_line > end_line then
              start_line, end_line = end_line, start_line
            end

            local relative = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
            if relative == "" then
              vim.notify("No file in current buffer", vim.log.levels.WARN)
              return
            end

            if start_line == end_line then
              relative = "@" .. relative .. ":" .. start_line
            else
              relative = "@" .. relative .. ":" .. start_line .. "-" .. end_line
            end

            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
            send_to_ai_cli(relative)
          end,
          desc = "Send file:lines to AI CLI chat box",
        },
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
