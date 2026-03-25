return {
  {
    mode = "n",
    { "<leader>s", "<nop>", desc = "Search & Replace" },
    {
      "<leader>sw",
      function()
        require("grug-far").open({
          prefills = {
            search = vim.fn.expand("<cword>"),
            paths = vim.fn.expand("%"),
          },
        })
      end,
      desc = "Search & Replace Word (file)",
    },

    {
      "<leader>sW",
      function()
        require("grug-far").open({
          prefills = { search = vim.fn.expand("<cword>") },
        })
      end,
      desc = "Search & Replace Word",
    },
    {
      "<leader>sr",
      function()
        require("grug-far").open({
          prefills = { paths = vim.fn.expand("%") },
        })
      end,
      desc = "Search & Replace (file)",
    },

    {
      "<leader>sR",
      function() require("grug-far").open() end,
      desc = "Search & Replace",
    },
  },

  {
    mode = "x",
    {
      "<leader>sr",
      function()
        require("grug-far").open({
          prefills = { paths = vim.fn.expand("%") },
          visualSelectionUsage = "auto-detect",
        })
      end,
      desc = "Search & Replace (file)",
    },

    {
      "<leader>sR",
      function()
        require("grug-far").open({
          visualSelectionUsage = "auto-detect",
        })
      end,
      desc = "Search & Replace",
    },
  },
}
