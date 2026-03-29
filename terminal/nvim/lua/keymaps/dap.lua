return {
  mode = "n",
  { "<leader>d", "nop", desc = "Debugger" },
  { "<leader>du", function() require("dap-view").toggle() end, desc = "Toggle UI" },
  { "<leader>ds", function() require("dap").continue() end, desc = "Start/continue" },
  { "<leader>dq", function() require("dap").terminate() end, desc = "Stop" },
  { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
  { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
  { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
  { "<leader>dB", function() require("dap").clear_breakpoints() end, desc = "Clear all breakpoints" },
}
