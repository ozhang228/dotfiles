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
      "<leader>gha",
      function() Snacks.picker.gh_pr() end,
      desc = "GH PRs (all open)",
    },
    {
      "<leader>ghm",
      function() Snacks.picker.gh_pr({ author = "@me" }) end,
      desc = "GH PRs (mine)",
    },
    {
      "<leader>ght",
      function() Snacks.picker.gh_pr({ label = "typescript" }) end,
      desc = "GH PRs (typescript)",
    },
    {
      "<leader>ghp",
      function() Snacks.picker.gh_pr({ label = "python" }) end,
      desc = "GH PRs (python)",
    },
  },
}
