return {
  "atiladefreitas/dooing",
  opts = {
    save_path = vim.fn.expand("~/forge/dooing_todos.json"),
    pretty_print_json = true,
    ui = {
      style = "modern",
    },
    priorities = {},
    priority_groups = {},
    window = {
      dimensions = function()
        return {
          width = math.floor(vim.o.columns * 0.98),
          height = math.floor(vim.o.lines * 0.98),
        }
      end,
      position = "center",
    },
    keymaps = {
      toggle_window = false,
      open_project_todo = false,
      show_due_notification = false,
      toggle_todo = false,
      toggle_priority = false,
      edit_priorities = false,
      new_todo = "n",
      create_nested_task = "N",
      edit_todo = "i",
      open_todo_scratchpad = "e",
    },
  },
  config = function(_, opts)
    require("dooing").setup(opts)

    local state = require("dooing.state")
    local function compare_todos_alphabetically(a, b)
      local a_text = a.todo.text:lower()
      local b_text = b.todo.text:lower()
      if a_text ~= b_text then return a_text < b_text end
      if a.todo.text ~= b.todo.text then return a.todo.text < b.todo.text end
      return a.todo.id < b.todo.id
    end

    state.compare_todos = compare_todos_alphabetically
    state.compare_todos_ignore_completion = compare_todos_alphabetically

    local dooing_keymaps = require("dooing.ui.keymaps")
    local setup_keymaps = dooing_keymaps.setup_keymaps
    dooing_keymaps.setup_keymaps = function()
      setup_keymaps()

      local constants = require("dooing.ui.constants")
      local function todo_at_cursor()
        local todo_index = require("dooing.ui.utils").todo_index_at_cursor()
        return todo_index and state.todos[todo_index]
      end

      local function render_todos() require("dooing.ui.rendering").render_todos() end

      vim.keymap.set("n", "x", function()
        local todo = todo_at_cursor()
        if not todo then return end

        todo.done = false
        todo.in_progress = not todo.in_progress
        todo.completed_at = nil
        state.save_todos()
        render_todos()
      end, { buffer = constants.buf_id, desc = "Toggle Todo Progress", nowait = true })
    end
  end,
  keys = {
    {
      "<leader>d",
      function() require("dooing").open_global_todo() end,
      desc = "Todos",
    },
  },
}
