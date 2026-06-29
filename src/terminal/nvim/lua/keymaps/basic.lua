local function resize(direction, amount)
  local cur = vim.fn.winnr()
  local has = {
    left  = vim.fn.winnr("h") ~= cur,
    right = vim.fn.winnr("l") ~= cur,
    up    = vim.fn.winnr("k") ~= cur,
    down  = vim.fn.winnr("j") ~= cur,
  }
  if direction == "left" then
    vim.cmd((has.left  and "vertical resize +" or "vertical resize -") .. amount)
  elseif direction == "right" then
    vim.cmd((has.right and "vertical resize +" or "vertical resize -") .. amount)
  elseif direction == "up" then
    vim.cmd((has.up    and "resize +" or "resize -") .. amount)
  elseif direction == "down" then
    vim.cmd((has.down  and "resize +" or "resize -") .. amount)
  end
end

return {
  {
    mode = "n",
    { "<leader>Q", "<cmd>qall<cr>", desc = "Quit Nvim" },
    { "<leader>w", "<cmd>w<cr>", desc = "Save Buffer" },
    { "<leader>q", "<cmd>close<cr>", desc = "Close Window" },
    { "<leader>c", "<cmd>bd<cr>", desc = "Close Buffer" },
    {
      "<leader>o",
      function()
        -- use current buffer path if valid else use cwd
        local buf_name = vim.api.nvim_buf_get_name(0)

        local path = buf_name ~= "" and buf_name or vim.fn.getcwd()
        if vim.fn.filereadable(path) == 0 and vim.fn.isdirectory(path) == 0 then path = vim.fn.getcwd() end

        require("mini.files").open(path, false)
        require("mini.files").reveal_cwd()
      end,
      desc = "Mini.files",
    },
    {
      "<leader>/",
      function() vim.cmd("normal gcc") end,
      desc = "Toggle Comment",
    },

    { "<Esc>", "<cmd>nohlsearch<CR>", desc = "Clear highlights on search" },
    { "<C-h>", "<C-w><C-h>", desc = "Move focus to the left window" },
    { "<C-l>", "<C-w><C-l>", desc = "Move focus to the right window" },
    { "<C-j>", "<C-w><C-j>", desc = "Move focus to the lower window" },
    { "<C-k>", "<C-w><C-k>", desc = "Move focus to the upper window" },
    { "<C-Up>",    function() resize("up",    5) end, desc = "Move divider up" },
    { "<C-Down>",  function() resize("down",  5) end, desc = "Move divider down" },
    { "<C-Left>",  function() resize("left",  5) end, desc = "Move divider left" },
    { "<C-Right>", function() resize("right", 5) end, desc = "Move divider right" },
    { "n", "nzz", desc = "Next search result with cursor centered" },
    { "N", "Nzz", desc = "Previous search result with cursor centered" },
    { "<C-D>", "<C-D>zz", desc = "Scroll down with cursor centered" },
    { "<C-U>", "<C-U>zz", desc = "Scroll up with cursor centered" },
    {
      "K",
      function()
        local line = vim.fn.line(".") - 1
        local diagnostics = vim.diagnostic.get(0, {
          lnum = line,
          severity = { min = vim.diagnostic.severity.WARN },
        })

        if #diagnostics > 0 then
          vim.diagnostic.open_float(nil, { focus = true })
        else
          vim.lsp.buf.hover()
        end
      end,
      desc = "Diagnostic / Hover",
    },
    {
      "<leader>|",
      function() vim.cmd("vsplit " .. vim.api.nvim_buf_get_name(0)) end,
      desc = "Vertical split",
    },
  },
  {
    mode = "t",
    { "<Esc><Esc>", "<C-\\><C-n>", desc = "Exit terminal mode", mode = "t" },
  },
  {
    mode = "v",
    {
      "<leader>/",
      function() vim.cmd("normal gc") end,
      desc = "Toggle Comment",
    },
  },
}
