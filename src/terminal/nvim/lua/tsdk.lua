-- astro-ls and mdx-language-server (Volar-based) require an explicit
-- typescript.tsdk init option, or they error asking for one instead of
-- falling back to a bundled copy.
local M = {}

function M.find(root_dir)
  if not root_dir then return nil end
  local path = vim.fs.joinpath(root_dir, "node_modules", "typescript", "lib")
  return vim.uv.fs_stat(path) and path or nil
end

return M
