return {
  "rmagatti/auto-session",
  lazy = false,
  opts = {
    continue_restore_on_error = false,
    git_use_branch_name = true,
    git_auto_restore_on_branch_change = true,
    -- exclude terminal buffers from saved sessions so restoring never touches them
    session_opts = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions",
    pre_restore_cmds = {
      function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end
      end,
    },
  },
}
