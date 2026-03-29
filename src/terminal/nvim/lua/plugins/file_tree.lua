return {
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

          -- Rule 1: hidden items always last
          if a_hidden ~= b_hidden then return not a_hidden end
          -- Rule 2: directories before files
          if a_dir ~= b_dir then return a_dir end
          -- Rule 3: group by extension (directories have no extension)
          if not a_dir and not b_dir then
            local a_ext = a.name:match("%.([^%.]+)$") or ""
            local b_ext = b.name:match("%.([^%.]+)$") or ""
            if a_ext ~= b_ext then return a_ext < b_ext end
          end
          -- Rule 4: case-insensitive alphabetical
          return a.name:lower() < b.name:lower()
        end)
        return entries
      end,
      filter = nil,
      prefix = nil,
    },
    mappings = {
      close = "<Leader>q",
      go_in = "L",
      go_in_plus = "",
      go_out = "H",
      go_out_plus = "",
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
  dependencies = {
    "echasnovski/mini.icons",
  },
}
