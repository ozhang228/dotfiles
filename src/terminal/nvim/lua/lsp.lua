-- Ensure ~/.cargo/bin is in PATH so rust-analyzer can spawn cargo/rustc
local cargo_bin = vim.fs.joinpath(vim.env.HOME, ".cargo/bin")
if vim.env.PATH and not vim.env.PATH:find(cargo_bin, 1, true) then vim.env.PATH = cargo_bin .. ":" .. vim.env.PATH end

-- enable all lsps in /lsp
local disabled = { "basedpyright" }

vim.lsp.config("*", { flags = { exit_timeout = 0 } })

local lsp_configs = {}
for _, f in pairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
  local server_name = vim.fn.fnamemodify(f, ":t:r")
  if not vim.tbl_contains(disabled, server_name) then table.insert(lsp_configs, server_name) end
end
vim.lsp.enable(lsp_configs)

-- Too noisy
vim.lsp.inlay_hint.enable(false)

local max_len = 30
local orig_handler = vim.lsp.handlers["textDocument/inlayHint"]
vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, config)
  if result then
    result = vim.tbl_filter(function(hint)
      local label = hint.label
      if type(label) == "table" then
        -- label can be a list of InlayHintLabelPart
        label = table.concat(vim.tbl_map(function(p) return p.value end, label))
      end
      return #label <= max_len
    end, result)
  end
  orig_handler(err, result, ctx, config)
end

local function renamed_file_uris(workspace_edit)
  local uris = vim.tbl_keys(workspace_edit.changes or {})
  for _, change in ipairs(workspace_edit.documentChanges or {}) do
    if change.textDocument then table.insert(uris, change.textDocument.uri) end
  end
  return uris
end

local function save_other_renamed_files(workspace_edit, current_bufnr)
  for _, uri in ipairs(renamed_file_uris(workspace_edit)) do
    local bufnr = vim.uri_to_bufnr(uri)
    if bufnr ~= current_bufnr and vim.bo[bufnr].modified then vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent write") end) end
  end
end

local apply_rename = vim.lsp.handlers["textDocument/rename"]
vim.lsp.handlers["textDocument/rename"] = function(err, result, ctx, config)
  apply_rename(err, result, ctx, config)
  if not err and result then save_other_renamed_files(result, ctx.bufnr) end
end
