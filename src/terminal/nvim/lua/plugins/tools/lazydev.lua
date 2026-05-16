return {
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    enabled = function(root_dir)
      local config = vim.fn.stdpath("config") --[[@as string]]
      return root_dir == config or root_dir == vim.uv.fs_realpath(config)
    end,
  },
}
