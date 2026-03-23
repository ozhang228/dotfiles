return {
  { "<leader>f", "<nop>", desc = "[F]ind" },
  {
    "<leader>ff",
    function() Snacks.picker.smart() end,
    desc = "Files (smart)",
  },
  {
    "<leader>fw",
    function() Snacks.picker.grep() end,
    desc = "Grep Word",
  },
  {
    "<leader>fb",
    function()
      Snacks.picker.buffers({
        limit = 8,
        sort_lastused = true,
      })
    end,
    desc = "Buffers",
  },
  {
    "<leader>fw",
    function() Snacks.picker.grep() end,
    desc = "Grep Word",
  },
  {
    "<leader>fd",
    function() Snacks.picker.diagnostics_buffer() end,
    desc = "Diagnostics (Buffer)",
  },
  {
    "<leader>fr",
    function() Snacks.picker.lsp_references() end,
    desc = "Lsp References",
  },

  {
    "<leader>fk",
    function() Snacks.picker.keymaps() end,
    desc = "Keymaps",
  },

  {
    "<leader>fn",
    function() Snacks.notifier.show_history() end,
    desc = "Notifications",
  },
  {
    "<leader>fh",
    function() Snacks.picker.help() end,
    desc = "Help",
  },
  {
    "<leader>f<enter>",
    function() Snacks.picker.resume() end,
    desc = "Resume",
  },
}
