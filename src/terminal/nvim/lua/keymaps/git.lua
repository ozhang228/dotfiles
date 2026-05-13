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
    { "<leader>gp", "<CMD>Octo pr list<CR>", desc = "GitHub: list PRs" },
    { "<leader>gr", "<CMD>Octo review start<CR>", desc = "GitHub: start review / diffs" },
    { "<leader>gf", "<CMD>Octo pr list_files<CR>", desc = "GitHub: list changed files" },
    { "<leader>gc", "<CMD>Octo comment add<CR>", desc = "GitHub: add comment" },
    { "<leader>gs", "<CMD>Octo review suggest<CR>", desc = "GitHub: add suggestion" },
    { "<leader>ge", "<CMD>Octo review submit<CR>", desc = "GitHub: submit review" },
  },
}
