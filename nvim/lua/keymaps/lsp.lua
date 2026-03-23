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
      function()
        -- go into buffer mode for renames
        vim.api.nvim_create_autocmd("CmdlineEnter", {
          once = true, -- fires once then deletes itself
          callback = function()
            local key = vim.api.nvim_replace_termcodes("<C-f>", true, false, true)
            vim.api.nvim_feedkeys(key, "c", false)
            vim.api.nvim_feedkeys("0", "n", false)
          end,
        })
        vim.lsp.buf.rename()
      end,
      desc = "Rename",
    },
    {
      "<leader>lR",
      function() vim.lsp.stop_client(vim.lsp.get_clients()) end,
      desc = "Restart",
    },
  },
}
