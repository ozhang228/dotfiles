return {
  {
    "echasnovski/mini.surround",
    version = false,
    opts = {},
  },
  {
    "echasnovski/mini.files",
    version = false,
    opts = {
      content = {
        sort = function(entries)
          table.sort(entries, function(a, b)
            local a_hidden = vim.startswith(a.name, ".")
            local b_hidden = vim.startswith(b.name, ".")
            local a_dir = a.fs_type == "directory"
            local b_dir = b.fs_type == "directory"

            -- Rule 1: directories before files
            if a_dir ~= b_dir then return a_dir end

            -- Rule 2: non-hidden before hidden
            if a_hidden ~= b_hidden then return not a_hidden end

            -- Rule 3: alphabetical within the same group
            return a.name < b.name
          end)
          return entries
        end,
        filter = nil,
        prefix = nil,
      },
      mappings = {
        close = "<Leader>q",
        go_in = "l",
        go_in_plus = "L",
        go_out = "h",
        go_out_plus = "H",
        mark_goto = "'",
        mark_set = "m",
        reset = "<BS>",
        reveal_cwd = "@",
        show_help = "g?",
        synchronize = "<Leader>w",
        trim_left = "<",
        trim_right = ">",
      },
      options = {
        permanent_delete = false,
        use_as_default_explorer = true,
      },
    },
  },
  {
    "echasnovski/mini.icons",
    opts = {
      filetype = {
        ["Harpoon"] = { glyph = "󱡀" },
        ["Trouble"] = { glyph = "󱍼" },
      },
    },
  },
}
