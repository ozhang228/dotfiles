local MiniIcons = require("mini.icons")

return {
  "b0o/incline.nvim",
  config = function()
    require("incline").setup({
      window = {
        padding = 0,
        margin = { horizontal = 0 },
      },
      render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        if filename == "" then filename = "[No Name]" end
        local icon, hl = MiniIcons.get("file", filename)
        local modified = vim.bo[props.buf].modified
        local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
        local bg = normal.bg and string.format("#%06x", normal.bg) or nil

        local dot = modified and { "◆ ", guifg = Palette.gold } or { "◆ ", guifg = Palette.foam }

        return {
          " ",
          dot,
          icon and { icon, " ", group = hl } or "",
          { filename, gui = modified and "bold,italic" or "bold" },
          " ",
          guibg = bg,
        }
      end,
    })
  end,
}
