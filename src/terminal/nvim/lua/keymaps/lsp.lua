return {
  {
    mode = "n",
    {
      "<leader>l",
      "nop",
      desc = "LSP",
    },
    {
      "<leader>li",
      function() vim.cmd("checkhealth vim.lsp") end,
      desc = "Lsp Info",
    },
    {
      "<leader>lf",
      "<cmd>ConformInfo<cr>",
      desc = "Formatter Info",
    },
    {
      "<leader>la",
      function() vim.lsp.buf.code_action() end,
      desc = "Code Action",
    },
    {
      "gl",
      function() vim.diagnostic.open_float() end,
      desc = "Show Diagnostics",
    },
    {
      "gd",
      function()
        vim.cmd("normal! m'")
        Snacks.picker.lsp_definitions({ jump = { reuse_win = false } })
      end,
      desc = "Go to Definition",
    },
    {
      "<leader>lr",
      function() vim.lsp.buf.rename() end,
      desc = "Rename",
    },
    {
      "<leader>lR",
      function() vim.lsp.stop_client(vim.lsp.get_clients()) end,
      desc = "Restart",
    },
  },
}
