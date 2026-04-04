return {
  "igorlfs/nvim-dap-view",
  lazy = false,
  opts = {
    winbar = {
      default_section = "scopes",
      sections = { "scopes", "watches", "breakpoints", "threads", "repl", "sessions" },
      base_sections = {
        scopes = { label = "Scopes", keymap = "S" },
        watches = { label = "Watches", keymap = "W" },
        breakpoints = { label = "Breakpoints", keymap = "B" },
        threads = { label = "Threads", keymap = "T" },
        repl = { label = "REPL", keymap = "R" },
        sessions = { label = "Sessions", keymap = "K" },
      },
    },

    windows = {
      size = 0.5,
      position = "right",
      terminal = {
        position = "right",
        size = 0.5,
      },
    },

    auto_toggle = "open_term",
  },
}
