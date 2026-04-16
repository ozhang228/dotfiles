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
  {
    "<leader>fc",
    function()
      local items = {}
      local handle = io.popen([[copyq eval "
      var lines = [];
      for (var i = 0; i < Math.min(size(), 50); i++) {
        var text = str(read(i)).split(String.fromCharCode(10)).join(' ').substring(0, 200);
        lines.push(i + '\t' + text);
      }
      print(lines.join(String.fromCharCode(10)));
    "]])
      if handle then
        for line in handle:lines() do
          local index, text = line:match("^(%d+)\t(.+)$")
          if index then table.insert(items, { index = tonumber(index), text = text }) end
        end
        handle:close()
      end

      Snacks.picker.pick({
        title = "Clipboard History",
        items = vim.tbl_map(function(item) return { text = item.text, index = item.index } end, items),
        format = function(item)
          return {
            { tostring(item.index) .. ": ", "SnacksPickerIdx" },
            { item.text, "Normal" },
          }
        end,
        confirm = function(picker, item)
          picker:close()
          if item then os.execute("copyq select " .. item.index) end
        end,
      })
    end,
    desc = "Clipboard History",
  },
}
