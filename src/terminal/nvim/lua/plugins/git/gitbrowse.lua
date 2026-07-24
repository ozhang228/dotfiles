return {
  "folke/snacks.nvim",
  opts = {
    gitbrowse = {
      enabled = true,
      what = "repo",
      url_patterns = {
        ["git%.drwholdings%.com"] = {
          branch = "/tree/{branch}",
          file = "/blob/{branch}/{file}#L{line_start}-L{line_end}",
          permalink = "/blob/{commit}/{file}#L{line_start}-L{line_end}",
          commit = "/commit/{commit}",
        },
      },
    },
  },
}
