return {
  "mfussenegger/nvim-dap",
  opts = {},
  config = function()
    for _, f in pairs(vim.api.nvim_get_runtime_file("dap/*.lua", true)) do
      dofile(f)
    end
  end,
}
