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
  },
}
