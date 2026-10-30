return {
  {
    mode = "n",
    {
      "K",
      function()
        local bufnr = vim.api.nvim_get_current_buf()
        local client = vim.lsp.get_clients({ bufnr = bufnr, name = "tsc" })[1]
        if not client then return vim.lsp.buf.hover() end

        local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
        params.verbosityLevel = 2
        client:request("textDocument/hover", params, function(err, result)
          if vim.api.nvim_get_current_buf() ~= bufnr then return end
          require("noice.lsp.hover").on_hover(err, result, { bufnr = bufnr })
        end, bufnr)
      end,
      desc = "Hover",
    },
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
      "<cmd>lsp restart<cr>",
      desc = "Restart LSP",
    },
  },
}
