local function send_to_ai(idx, fmt, ...)
  local cmd = vim.fn.getenv("AI_CLI_CMD")
  if not cmd or cmd == "" then
    vim.notify("AI_CLI_CMD not set", vim.log.levels.ERROR)
    return
  end

  local text = string.format(fmt, ...)

  local term = require("snacks").terminal.get(cmd, { count = 100 + idx })
  if not term then return end

  term:show()
  term:focus()

  vim.defer_fn(function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(text .. " ", true, false, true), "t", false) end, 200)
end

local keys = {
  { "<leader>a", "nop", desc = "AI" },
  { "<leader>al", "nop", desc = "Send file path", mode = "v" },
  { "<leader>a", "nop", desc = "AI", mode = "v" },
  { "<leader>as", "nop", desc = "Send current selection", mode = "v" },
}

for i = 1, 9 do
  local idx = i
  table.insert(keys, {
    mode = "n",
    {
      "<leader>a" .. idx,
      function() require("snacks").terminal.toggle(vim.fn.getenv("AI_CLI_CMD"), { count = 100 + idx }) end,
      desc = "AI Terminal " .. idx,
    },
  })
  table.insert(keys, {
    mode = "n",
    {
      "<leader>al" .. idx,
      function()
        local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
        local line = vim.fn.line(".")
        send_to_ai(idx, "@%s:%d", file, line)
      end,
      desc = "Send line to AI " .. idx,
    },
  })
  table.insert(keys, {
    mode = "v",
    {
      "<leader>as" .. idx,
      function()
        local start = vim.fn.line("v")
        local finish = vim.fn.line(".")
        if start > finish then
          start, finish = finish, start
        end

        local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
        send_to_ai(idx, "@%s:%d-%d", file, start, finish)
      end,
      desc = "Send selection to AI " .. idx,
    },
  })
end

return keys
