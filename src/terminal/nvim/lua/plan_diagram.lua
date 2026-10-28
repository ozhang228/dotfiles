local M = {}
local viewer
local url
local active_path

function M.open()
  local path = require("plans").current_path()
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

  local script = vim.fn.stdpath("config") .. "/plan-diagram/server.mjs"
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

function M.stop()
  if not viewer then
    vim.notify("Plan diagram server is not running")
    return
  end
  local process = viewer
  viewer, url, active_path = nil, nil, nil
  process:kill(15)
  vim.notify("Plan diagram server stopped")
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("plan_diagram", { clear = true }),
  callback = function()
    if viewer then viewer:kill(15) end
  end,
})

return M
