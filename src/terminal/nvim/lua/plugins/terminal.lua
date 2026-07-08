-- Reopening a hidden snacks terminal can leave libvterm's cursor row off by
-- one (the child process keeps writing to the PTY while the window is
-- closed, and Neovim's resync on reopen sometimes mis-tracks the row). A
-- real PTY resize (SIGWINCH) makes the child fully repaint, which is a more
-- reliable fix than Ctrl-L since some TUIs treat Ctrl-L as their own keybind.
local function nudge_terminal_resize(self)
  local channel = vim.bo[self.buf].channel
  if channel == 0 then return end
  local width = vim.api.nvim_win_get_width(self.win)
  local height = vim.api.nvim_win_get_height(self.win)
  if height <= 1 then return end
  pcall(vim.fn.jobresize, channel, width, height - 1)
  vim.schedule(function() pcall(vim.fn.jobresize, channel, width, height) end)
end

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
        on_win = nudge_terminal_resize,
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
