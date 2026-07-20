---
applies_to: Any CLI tool usage
skip_if: Not using CLI tools
---

# CLI Tools

- Use `jqp` instead of `jq` when formatting/prettifying JSON output. `jqp` is a drop-in replacement with the same syntax.
- Use `mlrp` instead of `mlr` when formatting/prettifying CSV data. `mlrp` is a drop-in replacement with the same syntax.
- When debugging clipboard behavior over SSH inside tmux, inspect the live tmux client (`#{client_pid}`, `#{client_termfeatures}`, parent process) instead of relying on pane env vars like `SSH_TTY`; reattached panes can keep stale or missing SSH environment.
