return {
  "atiladefreitas/dooing",
  opts = {
    save_path = vim.fn.expand("~/forge/dooing_todos.json"),
    pretty_print_json = true,
    ui = {
      style = "modern",
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
      new_todo = "n",
      create_nested_task = "N",
      edit_todo = "i",
      open_todo_scratchpad = "e",
    },
  },
  config = function(_, opts)
    require("dooing").setup(opts)

    local state = require("dooing.state")
    local toggle_todo = state.toggle_todo

    state.toggle_todo = function(index)
      toggle_todo(index)

      local completed = state.todos[index]
      if not completed or not completed.done then return end

      local deleted_ids = { [completed.id] = true }
      local found_descendant = true
      while found_descendant do
        found_descendant = false
        for _, todo in ipairs(state.todos) do
          if todo.parent_id and deleted_ids[todo.parent_id] and not deleted_ids[todo.id] then
            deleted_ids[todo.id] = true
            found_descendant = true
          end
        end
      end

      for todo_index = #state.todos, 1, -1 do
        if deleted_ids[state.todos[todo_index].id] then state.delete_todo(todo_index) end
      end
    end

    local dooing_keymaps = require("dooing.ui.keymaps")
    local setup_keymaps = dooing_keymaps.setup_keymaps
    dooing_keymaps.setup_keymaps = function()
      setup_keymaps()

      local constants = require("dooing.ui.constants")
      vim.keymap.set("n", "X", function()
        local todo_index = require("dooing.ui.utils").todo_index_at_cursor()
        local todo = todo_index and state.todos[todo_index]
        if not todo or not todo.in_progress then return end

        todo.in_progress = false
        state.save_todos()
        require("dooing.ui.rendering").render_todos()
      end, { buffer = constants.buf_id, desc = "Move Todo Back to Pending", nowait = true })
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
