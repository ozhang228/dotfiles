vim.o.mouse = "a"
vim.cmd.colorscheme("catppuccin-mocha")

vim.opt.shell = "/bin/zsh"

vim.g.have_nerd_font = true

vim.o.number = true
vim.o.relativenumber = true

-- Sync clipboard between OS and Neovim.
-- See `:help 'clipboard'`
vim.schedule(function() vim.o.clipboard = "unnamedplus" end)

-- A wrapped line will have same indent on every line
vim.o.breakindent = true

-- Store an undo file so undos persist through sessions
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or 1+ capital letters in the search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn (gutters) on by default
vim.o.signcolumn = "yes"

-- Decrease update time for better responsivenes in plugins
vim.o.updatetime = 250

-- Decrease mapped sequence wait time (makes mappings feel faster)
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Highlights which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- 24-bit color for nvim-notify
vim.opt.termguicolors = true

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- what to save in a session
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.api.nvim_create_autocmd("BufHidden", {
  callback = function(args)
    local buf = args.buf
    if not vim.api.nvim_buf_is_valid(buf) then return end
    if vim.bo[buf].buftype ~= "" then return end
    if not vim.bo[buf].buflisted then return end

    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then return end
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buf then return end
      end

      if vim.bo[buf].modified then
        local name = vim.api.nvim_buf_get_name(buf)
        local short = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"
        local choice = vim.fn.confirm("Save changes to " .. short .. "?", "&Yes\n&No\n&Cancel")
        if choice == 1 then
          vim.api.nvim_buf_call(buf, function() vim.cmd("write") end)
        elseif choice ~= 2 then
          return
        end
      end
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end,
})

vim.o.swapfile = false
