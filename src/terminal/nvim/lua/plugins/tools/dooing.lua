return {
  "atiladefreitas/dooing",
  opts = {
    save_path = vim.fn.expand("~/forge/dooing_todos.json"),
    pretty_print_json = true,
    ui = {
      style = "modern",
      progress = false,
      section_titles = {
        done = "BLOCKED",
      },
    },
    formatting = {
      done = {
        icon = "⊘",
      },
    },
    window = {
      dimensions = function()
        return {
          width = math.min(math.max(80, math.floor(vim.o.columns * 0.7)), vim.o.columns - 4),
          height = math.min(math.max(30, math.floor(vim.o.lines * 0.7)), vim.o.lines - 4),
        }
      end,
      position = "center",
    },
    keymaps = {
      toggle_window = false,
      open_project_todo = false,
      show_due_notification = false,
      delete_completed = false,
      new_todo = "n",
      create_nested_task = "N",
      edit_todo = "i",
      open_todo_scratchpad = "e",
    },
  },
  keys = {
    {
      "<leader>d",
      function() require("dooing").open_global_todo() end,
      desc = "Todos",
    },
  },
}
