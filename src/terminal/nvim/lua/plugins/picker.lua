return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    picker = {
      enabled = true,
      hidden = true,
      exclude = {
        ".git",
        "node_modules",
        ".venv",
        "__pycache__",
        ".mypy_cache",
        ".pytest_cache",
        ".ruff_cache",
        "dist",
        "target",
        "*.lock",
      },
      win = {
        list = {
          wo = {
            relativenumber = true,
          },
        },
      },
      formatters = {
        file = {
          filename_first = true,
        },
      },
      jump = {
        jumplist = false,
      },
      sources = {
        gh_pr = {
          confirm = "gh_browse",
        },
      },
      transform = function(item)
        local name = item.file and vim.fn.fnamemodify(item.file, ":t") or item.text or ""
        if name:sub(1, 1) == "_" then item.score_add = (item.score_add or 0) - 20 end
      end,
    },
  },
}
