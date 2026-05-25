return {
  "lervag/vimtex",
  lazy = false,
  init = function()
    vim.g.vimtex_view_method = "zathura"
    vim.g.vimtex_compiler_latexmk = { out_dir = "build" }
  end,
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "tex",
      callback = function(ev)
        require("which-key").add({
          buffer = ev.buf,
          { "<localleader>m", group = "LaTeX" },
          { "<localleader>mc", "<cmd>VimtexCompile<cr>", desc = "Compile (toggle)" },
          { "<localleader>mv", "<cmd>VimtexView<cr>", desc = "View PDF" },
          { "<localleader>me", "<cmd>VimtexErrors<cr>", desc = "View Errors" },
        })
      end,
    })
  end,
}
