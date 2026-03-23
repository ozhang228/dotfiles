local root_markers = {
  "tsconfig.json",
  "jsconfig.json",
  "package.json",
  "tsconfig.base.json",
}

return {
  cmd = { "tsgo", "--lsp", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  settings = {
    typescript = {
      preferences = {
        useAliasesForRenames = false,
      },
    },
    javascript = {
      preferences = {
        useAliasesForRenames = false,
      },
    },
  },
  root_dir = function(bufnr, on_dir)
    local markers = vim.fn.has("nvim-0.11.3") == 1 and { root_markers, { ".git" } } or vim.list_extend(vim.deepcopy(root_markers), { ".git" })
    local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
    local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })
    local project_root = vim.fs.root(bufnr, markers)
    if deno_lock_root and (not project_root or #deno_lock_root > #project_root) then return end
    if deno_root and (not project_root or #deno_root >= #project_root) then return end
    on_dir(project_root or vim.fn.getcwd())
  end,
}
