local M = {}
local no_toggles = { hidden = false, ignored = false, modified = false, follow = false, regex = false }
local viewer
local url
local active_path

local function directory()
  return vim.fn.stdpath("config") .. "/plans"
end

function M.current_path()
  local path = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0))
  local root = vim.uv.fs_realpath(directory())
  if path and root and path:sub(1, #root + 1) == root .. "/" and path:match("%.md$") then return path end
end

local function stop_diagram_if_active(path)
  if not viewer or not path or active_path ~= path then return end
  local process = viewer
  viewer, url, active_path = nil, nil, nil
  process:kill(15)
end

function M.open_diagram()
  local path = M.current_path()
  if not path then
    vim.notify("Open a plan buffer first", vim.log.levels.WARN)
    return
  end
  if vim.bo.modified then
    vim.notify("Save the plan before opening its diagram", vim.log.levels.WARN)
    return
  end
  if viewer and active_path == path then
    if url then
      local _, err = vim.ui.open(url)
      if err then vim.notify(err, vim.log.levels.ERROR) end
    end
    return
  end
  if viewer then viewer:kill(15) end
  if vim.fn.executable("node") == 0 or vim.fn.executable("mmdc") == 0 then
    vim.notify("Plan diagram requires node and mermaid-cli (mmdc)", vim.log.levels.ERROR)
    return
  end

  local script = directory() .. "/diagram/server.mjs"
  local output = ""
  local errors = ""
  active_path = path
  url = nil
  local process
  process = vim.system({ "node", script, path, vim.fn.exepath("mmdc") }, {
    text = true,
    stdout = function(_, data)
      if not data then return end
      output = output .. data
      if not output:find("\n", 1, true) then return end
      local port = tonumber(output:match("^(%d+)\n"))
      if not port then return end
      vim.schedule(function()
        if viewer ~= process or url then return end
        url = "http://localhost:" .. port
        local _, err = vim.ui.open(url)
        if err then vim.notify(err, vim.log.levels.ERROR) end
      end)
    end,
    stderr = function(_, data)
      if data then errors = errors .. data end
    end,
  }, function(result)
    vim.schedule(function()
      if viewer ~= process then return end
      viewer, url, active_path = nil, nil, nil
      if result.code ~= 0 and result.signal == 0 then vim.notify("Plan diagram: " .. errors, vim.log.levels.ERROR) end
    end)
  end)
  viewer = process
end

function M.stop_diagram()
  if not viewer then
    vim.notify("Plan diagram server is not running")
    return
  end
  local process = viewer
  viewer, url, active_path = nil, nil, nil
  process:kill(15)
  vim.notify("Plan diagram server stopped")
end

local function prompt_for_path(prompt, default, callback)
  vim.ui.input({ prompt = prompt, default = default }, function(name)
    if not name then return end
    name = vim.trim(name)
    if name == "" or name:find("[/\\%c]") or name == "." or name == ".." then
      vim.notify("Use a plan name without slashes or control characters", vim.log.levels.ERROR)
      return
    end
    local path = directory() .. "/" .. name .. ".md"
    callback(path, name)
  end)
end

local function create_plan()
  prompt_for_path("New plan: ", nil, function(path, name)
    if vim.uv.fs_stat(path) then
      vim.notify("Plan already exists: " .. name, vim.log.levels.ERROR)
      return
    end
    local result = vim.fn.writefile({ "# " .. name, "" }, path)
    if result ~= 0 then
      vim.notify("Could not create plan: " .. path, vim.log.levels.ERROR)
      return
    end
    vim.cmd.edit(vim.fn.fnameescape(path))
  end)
end

local function buffers_for_path(path)
  local real_path = vim.uv.fs_realpath(path)
  local buffers = {}
  if not real_path then return buffers end
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.uv.fs_realpath(vim.api.nvim_buf_get_name(buffer)) == real_path then
      buffers[#buffers + 1] = buffer
    end
  end
  return buffers
end

local function rename_plan(path)
  local name = vim.fn.fnamemodify(path, ":t:r")
  prompt_for_path("Rename plan: ", name, function(new_path, new_name)
    if new_path == path then return end
    if vim.uv.fs_stat(new_path) then
      vim.notify("Plan already exists: " .. new_name, vim.log.levels.ERROR)
      return
    end
    local real_path = vim.uv.fs_realpath(path)
    local buffers = buffers_for_path(path)
    for _, buffer in ipairs(buffers) do
      if vim.bo[buffer].modified then
        vim.notify("Save or discard unsaved changes before renaming " .. name, vim.log.levels.ERROR)
        return
      end
    end
    local ok, err = vim.uv.fs_rename(path, new_path)
    if not ok then
      vim.notify("Could not rename plan: " .. err, vim.log.levels.ERROR)
      return
    end
    stop_diagram_if_active(real_path)
    for _, buffer in ipairs(buffers) do
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
    vim.cmd.edit(vim.fn.fnameescape(new_path))
  end)
end

local function delete_plan(path)
  local name = vim.fn.fnamemodify(path, ":t:r")
  if vim.fn.confirm("Delete plan '" .. name .. "'?", "&Delete\n&Cancel", 2) ~= 1 then return end
  local real_path = vim.uv.fs_realpath(path)
  local buffers = buffers_for_path(path)
  for _, buffer in ipairs(buffers) do
    if vim.bo[buffer].modified then
      vim.notify("Save or discard unsaved changes before deleting " .. name, vim.log.levels.ERROR)
      return
    end
  end
  local ok, err = vim.uv.fs_unlink(path)
  if not ok then
    vim.notify("Could not delete plan: " .. err, vim.log.levels.ERROR)
    return
  end
  stop_diagram_if_active(real_path)
  for _, buffer in ipairs(buffers) do
    vim.api.nvim_buf_delete(buffer, { force = true })
  end
  M.pick()
end

local function toggle_task()
  local line = vim.api.nvim_get_current_line()
  local before, state, after = line:match("^(%s*[-*+] %[)(.)(%] .+)$")
  local next_state = { [" "] = "-", ["-"] = "x", x = " " }
  if before and next_state[state] then
    vim.api.nvim_set_current_line(before .. next_state[state] .. after)
  else
    vim.cmd("normal! +")
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("plan_diagram", { clear = true }),
    callback = function()
      if viewer then viewer:kill(15) end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost" }, {
    group = vim.api.nvim_create_augroup("plan_keymaps", { clear = true }),
    callback = function(args)
      if not M.current_path() then
        if vim.b[args.buf].plan_keymaps then
          for _, key in ipairs({ "<CR>", "<leader>dm", "<leader>dM" }) do
            vim.keymap.del("n", key, { buffer = args.buf })
          end
          vim.b[args.buf].plan_keymaps = nil
        end
        return
      end
      vim.b[args.buf].plan_keymaps = true
      vim.keymap.set("n", "<CR>", toggle_task, { buffer = args.buf, desc = "Cycle plan task state" })
      vim.keymap.set("n", "<leader>dm", M.open_diagram, {
        buffer = args.buf,
        desc = "Plan Mermaid diagram",
      })
      vim.keymap.set("n", "<leader>dM", M.stop_diagram, {
        buffer = args.buf,
        desc = "Stop plan diagram",
      })
    end,
  })
end

local function open_actions_menu(path)
  local actions = { { name = "New plan", key = "Ctrl-N", run = create_plan } }
  if path then
    actions[#actions + 1] = { name = "Rename plan", key = "Ctrl-R", run = function() rename_plan(path) end }
    actions[#actions + 1] = { name = "Delete plan", key = "Ctrl-X", run = function() delete_plan(path) end }
  end
  vim.ui.select(actions, {
    prompt = "Plan actions",
    format_item = function(action) return string.format("%-14s %s", action.name, action.key) end,
    snacks = { toggles = no_toggles },
  }, function(action)
    if action then
      action.run()
    else
      M.pick()
    end
  end)
end

function M.pick()
  local items = {}
  for _, path in ipairs(vim.fn.globpath(directory(), "*.md", false, true)) do
    items[#items + 1] = { text = vim.fn.fnamemodify(path, ":t:r"), file = path }
  end
  if #items == 0 then items[1] = { text = "Create your first plan", create = true } end
  Snacks.picker.pick({
    title = "Plans · ? help",
    items = items,
    toggles = no_toggles,
    format = function(item)
      local icon, hl = require("mini.icons").get(item.create and "lsp" or "file", item.create and "constructor" or item.file)
      return { { icon .. " ", hl }, { item.text } }
    end,
    actions = {
      plan_new = function(picker)
        picker:close()
        vim.schedule(create_plan)
      end,
      plan_rename = function(picker, item)
        if not item then return end
        picker:close()
        vim.schedule(function() rename_plan(item.file) end)
      end,
      plan_delete = function(picker, item)
        if not item then return end
        picker:close()
        vim.schedule(function() delete_plan(item.file) end)
      end,
      plan_menu = function(picker, item)
        local path = item and item.file
        picker:close()
        vim.schedule(function() open_actions_menu(path) end)
      end,
    },
    win = {
      input = {
        keys = {
          ["<c-n>"] = { "plan_new", mode = { "n", "i" }, desc = "New plan" },
          ["<c-r>"] = { "plan_rename", mode = { "n", "i" }, nowait = true, desc = "Rename plan" },
          ["<c-x>"] = { "plan_delete", mode = { "n", "i" }, desc = "Delete plan" },
          ["?"] = { "plan_menu", mode = { "n", "i" }, desc = "Plan actions" },
        },
      },
    },
    confirm = function(picker, item)
      picker:close()
      if not item then return end
      if item.create then
        vim.schedule(create_plan)
      else
        vim.cmd.edit(vim.fn.fnameescape(item.file))
      end
    end,
  })
end

return M
