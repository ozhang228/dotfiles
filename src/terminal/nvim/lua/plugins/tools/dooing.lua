return {
  "atiladefreitas/dooing",
  opts = {
    save_path = vim.fn.expand("~/anvil/dooing_todos.json"),
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
      toggle_todo = "<CR>",
      toggle_priority = false,
      edit_priorities = false,
      new_todo = "n",
      create_nested_task = "N",
      edit_todo = "i",
      open_todo_scratchpad = "e",
    },
  },
  config = function(_, opts)
    vim.loader.reset(vim.fn.stdpath("config"))
    local cache = package.loaded["lazy.core.cache"]
    if cache then cache.reset(vim.fn.stdpath("config")) end
    require("dooing").setup(opts)

    local dooing_input_titles = {
      [" Input "] = true,
      [" New to-do "] = true,
      [" Edit to-do "] = true,
      [" New sub-task "] = true,
      [" Time estimation "] = true,
      [" Edit tag "] = true,
      [" Search to-dos "] = true,
    }

    local function disable_completion_in_dooing_input(args)
      local buf = args.buf
      if vim.bo[buf].buftype ~= "nofile" then return end

      local win = vim.fn.bufwinid(buf)
      if win == -1 then return end

      local title = vim.api.nvim_win_get_config(win).title
      if type(title) ~= "table" or type(title[1]) ~= "table" then return end
      if not dooing_input_titles[title[1][1]] then return end

      vim.b[buf].completion = false
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
      group = vim.api.nvim_create_augroup("dooing_completion", { clear = true }),
      callback = disable_completion_in_dooing_input,
    })

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

      vim.keymap.set("n", "<CR>", function()
        local todo = todo_at_cursor()
        if not todo then return end

        todo.done = not todo.done
        todo.in_progress = false
        todo.completed_at = todo.done and os.time() or nil
        state.save_todos()
        render_todos()
      end, { buffer = constants.buf_id, desc = "Toggle Todo Done", nowait = true })

      vim.keymap.set("n", "m", function() require("dooing_diagram").open() end, {
        buffer = constants.buf_id,
        desc = "Open Todo Diagram (auto refresh)",
        nowait = true,
      })

      vim.keymap.set("n", "M", function() require("dooing_diagram").stop() end, {
        buffer = constants.buf_id,
        desc = "Stop Todo Diagram server",
        nowait = true,
      })

      vim.keymap.set("n", require("dooing.config").options.keymaps.toggle_help, function()
        require("dooing.ui.components").create_help_window()
        local buf = constants.help_buf_id
        if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
        local count = vim.api.nvim_buf_line_count(buf)
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, 0, 0, false, {
          " CUSTOM KEYS",
          "   m   Open live diagram (starts a fresh server if stopped)",
          "   M   Stop diagram server",
          "   x   Toggle in progress",
          "   Enter   Toggle done",
          "",
        })
        vim.bo[buf].modifiable = false
        vim.api.nvim_buf_add_highlight(buf, constants.ns_id, "DooingSectionTitle", 0, 0, -1)
        vim.api.nvim_buf_add_highlight(buf, constants.ns_id, "DooingQuickKey", 1, 3, 4)
        vim.api.nvim_buf_add_highlight(buf, constants.ns_id, "DooingQuickKey", 2, 3, 4)
        local window = vim.api.nvim_win_get_config(constants.help_win_id)
        window.height = math.min(count + 6, vim.o.lines - 4)
        vim.api.nvim_win_set_config(constants.help_win_id, window)
      end, { buffer = constants.buf_id, desc = "Todo Help", nowait = true })

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
