return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    image = {
      enabled = true,
      math = {
        latex = {
          font_size = "normalsize",
        },
      },
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "tex",
      callback = function(ev) vim.b[ev.buf].snacks_image_attached = true end,
    })
  end,
}
