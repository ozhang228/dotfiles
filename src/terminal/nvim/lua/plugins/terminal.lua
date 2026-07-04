return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    terminal = {
      enabled = true,
      win = {
        style = "float",
        border = "rounded",
        backdrop = 60,
        width = 0.98,
        height = 0.98,
        keys = {
          term_normal = {
            "<leader><esc>",
            function(self) vim.cmd("stopinsert") end,
            mode = "t",
            desc = "Exit to normal mode",
          },
          to_vsplit = {
            "<leader>|",
            function(self)
              local buf = self.buf
              self:hide()
              vim.cmd("vertical sbuffer " .. buf)
              vim.cmd("startinsert")
            end,
            mode = "t",
            desc = "Move to vertical split",
          },
        },
      },
    },
  },
}
