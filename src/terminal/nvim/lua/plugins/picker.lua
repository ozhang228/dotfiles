return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    picker = {
      enabled = true,
      hidden = true,
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
      transform = function(item)
        local name = item.file and vim.fn.fnamemodify(item.file, ":t") or item.text or ""
        if name:sub(1, 1) == "_" then
          item.score_add = (item.score_add or 0) - 20
        end
      end,
    },
  },
}
