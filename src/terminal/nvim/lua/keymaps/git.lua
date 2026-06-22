return {
  {
    mode = "n",
    { "<leader>g", "nop", desc = "Git" },
    {
      "<leader>gg",
      function() Snacks.lazygit() end,
      desc = "Lazygit",
    },
  },
}
