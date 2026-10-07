local M = {}
local viewer
local url
local active_path

function M.open()
  local state = require("dooing.state")
  local path = state.current_save_path or require("dooing.config").options.save_path
  if viewer and active_path == path then
    if url then
      local _, err = vim.ui.open(url)
      if err then vim.notify(err, vim.log.levels.ERROR) end
    end
    return
  end
  if viewer then viewer:kill(15) end
  if vim.fn.executable("node") == 0 or vim.fn.executable("mmdc") == 0 then
    vim.notify("Todo diagram requires node and mermaid-cli (mmdc)", vim.log.levels.ERROR)
    return
  end

  local script = vim.fn.stdpath("config") .. "/dooing-diagram/server.mjs"
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
      if result.code ~= 0 and result.signal == 0 then vim.notify("Todo diagram: " .. errors, vim.log.levels.ERROR) end
    end)
  end)
  viewer = process
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("dooing_diagram", { clear = true }),
  callback = function()
    if viewer then viewer:kill(15) end
  end,
})

return M
