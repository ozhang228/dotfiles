local function leet_keymaps(bufnr)
  require("which-key").add({
    { "<leader>r", group = "Leetcode", buffer = bufnr },
    { "<leader>rp", "<cmd>Leet list<cr>", desc = "Problems", buffer = bufnr },
    { "<leader>rr", "<cmd>Leet run<cr>", desc = "Run", buffer = bufnr },
    { "<leader>rs", "<cmd>Leet submit<cr>", desc = "Submit", buffer = bufnr },
  })
end

return {
  "kawre/leetcode.nvim",
  cmd = "Leet",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    lang = "python3",
    plugins = {
      non_standalone = true,
    },
    hooks = {
      ---@type fun()[]
      enter = {
        -- the menu buffer is focused right after mounting, so grab it here
        function() leet_keymaps(vim.api.nvim_get_current_buf()) end,
      },
      ---@type fun(question: lc.ui.Question)[]
      question_enter = {
        function(question) leet_keymaps(question.bufnr) end,
      },
    },
  },
}
