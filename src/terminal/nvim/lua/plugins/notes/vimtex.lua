return {
  "lervag/vimtex",
  lazy = false,
  init = function()
    vim.g.vimtex_view_method = "zathura"
    -- Send all aux files (and the PDF) to a build/ subdir so the source
    -- directory stays clean. SyncTeX still works since vimtex knows out_dir.
    vim.g.vimtex_compiler_latexmk = { out_dir = "build" }
  end,
}
