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
        jumplist = true,
      },
      sources = {
        select = {
          kinds = {
            codeaction = {
              matcher = { sort_empty = true },
              sort = { fields = { "action_priority", "preferred_priority", "score:desc", "idx" } },
              transform = function(item)
                local action = item.item.action
                local kind = action.kind or ""
                local title = action.title:lower()
                local is_import = kind:lower():find("import", 1, true) or title:find("%f[%a]imports?%f[%A]")
                if action.disabled then
                  item.action_priority = 5
                elseif kind == "refactor" or kind:sub(1, 9) == "refactor." then
                  item.action_priority = 4
                elseif
                  is_import
                  and (
                    kind == "source.organizeImports"
                    or kind == "source.sortImports"
                    or kind == "source.removeUnusedImports"
                    or title:match("^organize")
                    or title:match("^sort")
                    or title:match("^remove")
                  )
                then
                  item.action_priority = 3
                elseif is_import then
                  item.action_priority = 1
                elseif kind == "quickfix" or kind:sub(1, 9) == "quickfix." then
                  item.action_priority = 2
                else
                  item.action_priority = 4
                end
                item.preferred_priority = action.isPreferred and 0 or 1
              end,
            },
          },
        },
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
