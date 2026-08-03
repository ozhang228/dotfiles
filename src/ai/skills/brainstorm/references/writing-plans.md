# Writing Plans

Format and rules for the implementation plan produced at the end of brainstorming. The plan is a step-by-step document for an engineer with zero codebase context.

## What the plan contains

- **File structure** — exact paths for files to create or modify, locked in before tasks are written
- **TDD tasks** — each task follows: write failing test → run to confirm fail → implement → run to confirm pass. Do NOT include "stop for user review" between tasks — the default is to run the full plan end-to-end with a single review at the end. The user handles all commits, so never include commit steps in the plan.
- **No placeholders** — every step has exact commands and expected output. Include code only when it clarifies a non-obvious contract; do not duplicate the implementation in the plan.

## Where plans are saved

`cwd/docs/PLAN.md`

## Key quality rules

- Each task produces working, testable software on its own
- If the spec covers multiple independent subsystems, split into separate plans
- Exact file paths always — no `path/to/file.py`
- Keep each step concrete enough to execute without rediscovering the design
