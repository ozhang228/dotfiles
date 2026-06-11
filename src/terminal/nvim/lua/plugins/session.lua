return {
  "rmagatti/auto-session",
  lazy = false,
  opts = {
    continue_restore_on_error = false,
    git_use_branch_name = true,
    git_auto_restore_on_branch_change = true,
    session_opts = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions",
    -- keep terminal buffers (and their running jobs) alive across the branch-change
    -- restore instead of wiping them, so switching branches doesn't tear down terminals
    preserve_buffer_on_restore = function(bufnr)
      return vim.bo[bufnr].buftype == "terminal"
    end,
    pre_restore_cmds = {
      -- snacks terminals are floating windows. preserve_buffer_on_restore keeps the
      -- buffer alive, but the session's `silent only` fails with E5601 if a float is
      -- the only thing left. Close the float windows (buffer+job survive) before restore.
      function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local cfg = vim.api.nvim_win_get_config(win)
          local buf = vim.api.nvim_win_get_buf(win)
          if cfg.relative ~= "" and vim.bo[buf].buftype == "terminal" then
            pcall(vim.api.nvim_win_close, win, false)
          end
        end
      end,
    },
  },
}
