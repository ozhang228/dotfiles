return {
  "3rd/diagram.nvim",
  ft = { "markdown" },
  dependencies = {
    "3rd/image.nvim",
  },
  opts = {
    renderer_options = {
      mermaid = {
        background = "transparent",
        theme = "dark",
        cli_args = { "-p", vim.fn.stdpath("config") .. "/puppeteer-config.json" },
      },
    },
    events = {
      render_buffer = { "InsertLeave", "BufWinEnter" },
    },
  },
  config = function(_, opts)
    require("diagram").setup(vim.tbl_deep_extend("force", {
      integrations = {
        require("diagram.integrations.markdown"),
      },
    }, opts))
  end,
}
