local keys = {
  mode = "n",
  {
    "<leader>t",
    function() end,
    desc = "Terminal",
  },
}

for i = 1, 9 do
  local idx = i
  table.insert(keys, {
    "<leader>t" .. idx,
    function() require("snacks").terminal.toggle(nil, { count = idx }) end,
    desc = "Terminal " .. idx,
  })
end

return keys
