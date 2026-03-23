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
      "gd",
      function() vim.lsp.buf.definition() end,
      desc = "Go to Definition",
    },
    {
      "<leader>lr",
      function() vim.lsp.buf.rename() end,
      desc = "Rename",
    },
  },
}
