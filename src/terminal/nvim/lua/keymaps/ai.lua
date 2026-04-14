local function send_to_ai(fmt, ...)
  local cmd = vim.fn.getenv("AI_CLI_CMD")
  if not cmd or cmd == "" then
    vim.notify("AI_CLI_CMD not set", vim.log.levels.ERROR)
    return
  end

  local text = string.format(fmt, ...)

  local term = require("snacks").terminal.get(cmd)
  if not term then return end

  term:show()
  term:focus()

  vim.defer_fn(function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(text .. " ", true, false, true), "t", false) end, 200)
end

return {
  { "<leader>a", "nop", desc = "AI" },
  { "<leader>a", "nop", desc = "AI", mode = "v" },
  {
    "<leader>at",
    function() require("snacks").terminal.toggle(vim.fn.getenv("AI_CLI_CMD")) end,
    desc = "AI Terminal",
  },
  {
    "<leader>al",
    function()
      local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
      local line = vim.fn.line(".")
      send_to_ai("@%s:%d", file, line)
    end,
    desc = "Send line to AI",
  },
  {
    "<leader>as",
    mode = "v",
    function()
      local start = vim.fn.line("v")
      local finish = vim.fn.line(".")
      if start > finish then
        start, finish = finish, start
      end

      local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
      send_to_ai("@%s:%d-%d", file, start, finish)
    end,
    desc = "Send selection to AI",
  },
}
