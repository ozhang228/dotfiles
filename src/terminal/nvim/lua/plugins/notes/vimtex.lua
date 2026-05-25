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
        local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc }) end
        map("<localleader>m", "nop", "LaTeX (math)")
        map("<localleader>mc", "<cmd>VimtexCompile<cr>", "Compile (toggle)")
        map("<localleader>mv", "<cmd>VimtexView<cr>", "View PDF")
      end,
    })
  end,
}
