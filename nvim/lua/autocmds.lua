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

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "LspInlayHint", {
      fg = Palette.peach,
      bg = Palette.teal,
      italic = true,
    })
  end,
})
