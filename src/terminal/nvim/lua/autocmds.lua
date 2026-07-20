-- Keep kitty tab title in sync with git branch while nvim is running.
-- fish_title only fires at the shell prompt, so branch changes inside nvim
-- (e.g. lazygit checkout) never update it. We set the title directly via
-- vim.o.titlestring instead, mirroring fish_title's format.
vim.o.title = true
local function update_title()
  local tab_label = os.getenv("KITTY_TAB_TITLE") or ""
  local branch = vim.b.gitsigns_head or ""
  local label = tab_label ~= "" and tab_label or vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
  vim.o.titlestring = branch ~= "" and (label .. " [" .. branch .. "]") or label
end

vim.api.nvim_create_autocmd({ "WinEnter", "DirChanged", "User" }, {
  desc = "Sync kitty tab title with git branch",
  pattern = { "*", "*", "GitSignsUpdate" },
  callback = update_title,
})

vim.api.nvim_create_autocmd("FileType", {
  desc = "Enable spellcheck for prose filetypes",
  pattern = { "markdown", "tex", "gitcommit", "text" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  desc = "Start treesitter highlighting for filetypes with an installed parser",
  callback = function(ev) pcall(vim.treesitter.start, ev.buf) end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Open file at the last position it was edited earlier",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then vim.api.nvim_win_set_cursor(0, mark) end
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
  desc = "Run lint after write and on buffer enter",
  callback = function() require("lint").try_lint() end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesActionRename",
  callback = function(event) require("snacks").rename.on_rename_file(event.data.from, event.data.to) end,
  desc = "LSP Rename on mini files changes",
})

vim.api.nvim_create_autocmd("BufLeave", {
  desc = "Delete normal file buffers once no window shows them, so they don't pile up without tabs",
  callback = function(ev)
    local bufnr = ev.buf
    if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].modified then return end
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) and #vim.fn.win_findbuf(bufnr) == 0 then
        pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("TermRequest", {
  desc = "Notify when a :terminal child emits OSC-9 (e.g. Claude Stop hook)",
  callback = function(ev)
    local seq = type(ev.data) == "table" and ev.data.sequence or ev.data or ""
    local msg = seq:match("\027%]9;(.-)\007") or seq:match("\027%]9;(.-)\027\\") or seq:match("\027%]9;(.+)")
    if not msg then return end
    if vim.api.nvim_get_current_buf() == ev.buf then return end
    vim.notify(msg, vim.log.levels.INFO, { title = "Terminal" })
    io.stdout:write("\a")
    io.stdout:flush()
  end,
})

vim.api.nvim_create_autocmd("TermRequest", {
  desc = "Forward OSC-52 clipboard writes from a :terminal child to the host terminal",
  callback = function(ev)
    local seq = type(ev.data) == "table" and ev.data.sequence or ev.data or ""
    if seq:sub(1, 5) ~= "\027]52;" then return end
    io.stdout:write(seq)
    io.stdout:flush()
  end,
})
