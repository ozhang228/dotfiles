-- enable all lsps in /lsp
local disabled = { "vtsls" }

local lsp_configs = {}
for _, f in pairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
  local server_name = vim.fn.fnamemodify(f, ":t:r")
  if not vim.tbl_contains(disabled, server_name) then table.insert(lsp_configs, server_name) end
end
vim.lsp.enable(lsp_configs)

vim.lsp.inlay_hint.enable(true)
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
