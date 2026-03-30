return {
  { "<leader>f", "<nop>", desc = "Find" },
  {
    "<leader>ff",
    function() Snacks.picker.smart({ multi = { "recent", "files" } }) end,
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
    "<leader>fW",
    function() Snacks.picker.grep_word() end,
    desc = "Grep Word Under Cursor",
  },
  {
    "<leader>fd",
    function() Snacks.picker.diagnostics_buffer() end,
    desc = "Diagnostics (Buffer)",
  },
  {
    "<leader>fD",
    function() Snacks.picker.diagnostics() end,
    desc = "Diagnostics",
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
