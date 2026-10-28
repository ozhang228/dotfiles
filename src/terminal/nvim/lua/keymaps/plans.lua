return {
  { "<leader>d", function() require("plans").pick() end, desc = "Plans" },
  { "<leader>dm", function() require("plan_diagram").open() end, desc = "Plan Mermaid diagram" },
  { "<leader>dM", function() require("plan_diagram").stop() end, desc = "Stop plan diagram" },
}
