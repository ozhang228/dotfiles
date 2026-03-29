return {
  {
    mode = "n",
    {
      "<leader>p",
      function() end,
      desc = "Plugins",
    },
    {
      "<leader>pg",
      "<cmd>Lazy<cr>",
      desc = "GUI",
    },
    {
      "<leader>pi",
      function() require("lazy").install() end,
      desc = "Install",
    },
    {
      "<leader>ps",
      function() require("lazy").sync() end,
      desc = "Sync",
    },
    {
      "<leader>pu",
      function() require("lazy").update() end,
      desc = "Update",
    },
    {
      "<leader>pc",
      function() require("lazy").clean() end,
      desc = "Clean",
    },
  },
}
