# Grapple
{
  "cbochs/grapple.nvim",
  dependencies = {
    { "nvim-tree/nvim-web-devicons" },
  },
  opts = {
    scope = "git_branch",
    icons = true,
    quick_select = "123456789",
  },
},
["<Leader>h"] = { "Nop", desc = require("mini.icons").get("filetype", "Harpoon") .. " Grapple" },
["<Leader>hm"] = {
"<CMD>Grapple toggle_tags<CR>",
desc = "Toggle Grapple Quick Menu",
},
["<Leader>ha"] = {
"<CMD> Grapple toggle<CR>",
desc = "Add File",
},
["<Leader>hh"] = {
"<CMD> Grapple cycle_tags prev<CR>",
desc = "Go to previous Grapple mark",
},
["<Leader>hl"] = {
"<CMD> Grapple cycle_tags next<CR>",
desc = "Go to next Grapple mark",
},
