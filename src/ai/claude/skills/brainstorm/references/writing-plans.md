# Writing Plans

When transitioning from brainstorm to implementation, invoke the `writing-plans` skill. It produces a step-by-step plan for an engineer with zero codebase context.

## What the plan contains

- **File structure** — exact paths for files to create or modify, locked in before tasks are written
- **TDD tasks** — each task follows: write failing test → run to confirm fail → implement → run to confirm pass. Do NOT include "stop for user review" between tasks — the default is to run the full plan end-to-end with a single review at the end. The user handles all commits, so never include commit steps in the plan.
- **No placeholders** — every step has actual code, exact commands, and expected output
- Principles: DRY, YAGNI, TDD

## Where plans are saved

`cwd/docs/PLAN.md`

## Execution options (offered after plan is saved)

1. **Subagent-driven** (recommended) — fresh subagent per task, review between tasks
2. **Inline execution** — executes tasks in the current session with checkpoints

## Key quality rules

- Each task produces working, testable software on its own
- If the spec covers multiple independent subsystems, split into separate plans
- Exact file paths always — no `path/to/file.py`
- Complete code in every step that touches code
