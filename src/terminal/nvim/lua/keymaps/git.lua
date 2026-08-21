local function open_blame_pr()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Current buffer has no file to blame", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fn.fnamemodify(file, ":h")
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local blame = vim.system({
    "git",
    "blame",
    "--porcelain",
    "-L",
    ("%d,%d"):format(line, line),
    "--",
    vim.fn.fnamemodify(file, ":t"),
  }, { cwd = cwd, text = true }):wait()

  if blame.code ~= 0 then
    vim.notify(vim.trim(blame.stderr), vim.log.levels.ERROR, { title = "Git blame" })
    return
  end

  local commit = blame.stdout:match("^(%x+)")
  if not commit then
    vim.notify("Git blame returned no commit", vim.log.levels.ERROR, { title = "Git blame" })
    return
  end
  if commit:match("^0+$") then
    vim.notify("This line has not been committed yet", vim.log.levels.WARN, { title = "Git blame" })
    return
  end

  local remote = vim.system({ "git", "remote", "get-url", "origin" }, { cwd = cwd, text = true }):wait()
  if remote.code ~= 0 then
    vim.notify(vim.trim(remote.stderr), vim.log.levels.ERROR, { title = "Git blame" })
    return
  end

  local remote_url = vim.trim(remote.stdout)
  local host, repo = remote_url:match("^https?://([^/]+)/(.+)$")
  if not host then host, repo = remote_url:match("^git@([^:]+):(.+)$") end
  if not host then host, repo = remote_url:match("^ssh://git@([^/]+)/(.+)$") end
  if not host or not repo then
    vim.notify("Could not identify the GitHub repository from origin", vim.log.levels.ERROR, { title = "Git blame" })
    return
  end
  repo = repo:gsub("%.git$", "")

  vim.system({
    "gh",
    "api",
    "--hostname",
    host,
    "repos/" .. repo .. "/commits/" .. commit .. "/pulls",
    "--jq",
    ".[0].html_url // empty",
  }, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      local url = vim.trim(result.stdout)
      if result.code == 0 and url ~= "" then
        vim.ui.open(url)
        return
      end

      vim.notify("No associated PR found; opening the blamed commit", vim.log.levels.INFO, { title = "Git blame" })
      Snacks.gitbrowse({ what = "commit", commit = commit })
    end)
  end)
end

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
      "<leader>gb",
      open_blame_pr,
      desc = "Open Blame PR",
    },
    {
      "<leader>gh",
      function() Snacks.picker.gh_pr() end,
      desc = "GH PRs (all open)",
    },
    {
      "<leader>gm",
      function() Snacks.picker.gh_pr({ author = "@me" }) end,
      desc = "GH PRs (mine)",
    },
    {
      "<leader>go",
      function() Snacks.gitbrowse({ what = "permalink" }) end,
      desc = "Open on GitHub",
    },
  },
}
