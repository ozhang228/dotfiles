return {
  {
    mode = "n",
    { "<leader>g", "nop", desc = "Git" },
    {
      "<leader>gg",
      function() Snacks.lazygit() end,
      desc = "Lazygit",
    },
    {
      "<leader>gh",
      function() Snacks.picker.gh_pr() end,
      desc = "PRs",
    },
  },
}
