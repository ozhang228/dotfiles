local M = {}

local function directory()
  return vim.fn.stdpath("config") .. "/plans"
end

function M.current_path()
  local path = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0))
  local root = vim.uv.fs_realpath(directory())
  if path and root and path:sub(1, #root + 1) == root .. "/" and path:match("%.md$") then return path end
end

local function create_plan()
  vim.ui.input({ prompt = "Plan name: " }, function(name)
    if not name then return end
    name = vim.trim(name)
    if name == "" or name:find("[/\\%c]") or name == "." or name == ".." then
      vim.notify("Use a plan name without slashes or control characters", vim.log.levels.ERROR)
      return
    end
    local path = directory() .. "/" .. name .. ".md"
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
      vim.keymap.set("n", "<leader>dm", function() require("plan_diagram").open() end, {
        buffer = args.buf,
        desc = "Plan Mermaid diagram",
      })
      vim.keymap.set("n", "<leader>dM", function() require("plan_diagram").stop() end, {
        buffer = args.buf,
        desc = "Stop plan diagram",
      })
    end,
  })
end

function M.pick()
  local items = { { text = "+ New plan", create = true } }
  for _, path in ipairs(vim.fn.globpath(directory(), "*.md", false, true)) do
    items[#items + 1] = { text = vim.fn.fnamemodify(path, ":t:r"), file = path }
  end
  Snacks.picker.pick({
    title = "Plans",
    items = items,
    format = function(item) return { { item.text } } end,
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
