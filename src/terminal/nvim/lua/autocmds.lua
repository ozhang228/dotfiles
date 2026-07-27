local oxlint_config_files = {
  ".oxlintrc.json",
  ".oxlintrc.jsonc",
  "oxlint.config.ts",
  "oxlint.config.mts",
}

local oxlint_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

local function lint_buffer(event)
  local lint = require("lint")
  local filetype = vim.bo[event.buf].filetype
  if not oxlint_filetypes[filetype] then
    lint.try_lint()
    return
  end

  local buffer_directory = vim.fs.dirname(vim.api.nvim_buf_get_name(event.buf))
  local oxlint_root = vim.fs.root(buffer_directory, oxlint_config_files)

  if oxlint_root then
    vim.diagnostic.reset(lint.get_namespace("eslint_d"), event.buf)
    local oxlint_binary = vim.fs.joinpath(oxlint_root, "node_modules", ".bin", "oxlint")
    if vim.uv.fs_stat(oxlint_binary) then
      lint.linters.oxlint.cmd = oxlint_binary
    else
      lint.linters.oxlint.cmd = "oxlint"
    end
    lint.try_lint("oxlint", { cwd = oxlint_root })
    return
  end

  local package_root = vim.fs.root(buffer_directory, "package.json")
  vim.diagnostic.reset(lint.get_namespace("oxlint"), event.buf)
  lint.try_lint(nil, { cwd = package_root })
end

vim.api.nvim_create_autocmd("FileType", {
  desc = "Enable spellcheck for prose filetypes",
  pattern = { "markdown", "tex", "gitcommit", "text" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
    vim.opt_local.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
  end,
})

-- No dedicated mdx parser exists; highlight .mdx with the markdown grammar.
vim.filetype.add({ extension = { mdx = "mdx" } })
vim.treesitter.language.register("markdown", "mdx")

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
  callback = lint_buffer,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesActionRename",
  callback = function(event) require("snacks").rename.on_rename_file(event.data.from, event.data.to) end,
  desc = "LSP Rename on mini files changes",
})
