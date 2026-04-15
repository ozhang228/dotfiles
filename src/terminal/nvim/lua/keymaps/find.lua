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
    function()
      local cwd = vim.uv.cwd()
      Snacks.picker.pick({
        title = "Directories",
        finder = function(opts, ctx)
          return require("snacks.picker.source.proc").proc(
            ctx:opts({
              cmd = "fd",
              args = { "--type", "d", "--hidden", "--exclude", ".git", "--color", "never" },
              transform = function(item)
                item.cwd = cwd
                item.file = item.text
                item.dir = true
              end,
            }),
            ctx
          )
        end,
        format = "file",
        confirm = function(picker, item)
          picker:close()
          if item then
            local path = Snacks.picker.util.path(item) or item.file
            require("mini.files").open(path, false)
          end
        end,
      })
    end,
    desc = "Find Directory → Mini.files",
  },
  {
    "<leader>fq",
    function() Snacks.picker.diagnostics_buffer() end,
    desc = "Diagnostics (Buffer)",
  },
  {
    "<leader>fQ",
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
