---
name: brainstorm
description: You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation.
allowed-tools: Read, Grep, Glob
---

# Brainstorming

- Help turn ideas into fully formed designs and specs through natural collaborative dialogue.
- Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.
- Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.

## Challenge the premise first

Before going deep on design, sanity-check the work itself. The user often has a thread to pull but hasn't decided whether the work is worth doing — your job is to surface that, not to assume it.

- Is the request redundant with an existing system? (e.g. "double-alert in addition to the upstream alert" — what failure mode does the new copy actually catch?)
- Is the user's framing the right one, or is there a simpler interpretation of their goal?
- Is there an existing solution they don't know about?

If the premise looks shaky, raise it early — before clarifying questions, not after design. A short "before we go deep, here's what I'd push back on…" is cheaper than a full design that ends with the user saying "actually, should we even do this?"

## Anti-Pattern: "This Is Too Simple To Need A Design"

- Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Exception: type-checker / build-fix passthrough

- Skip the brainstorm workflow entirely when the task is purely "make ty/mypy happy" or "make the build pass" with **no behavior change and no design choice** — there's a wrong type and a right type, no tradeoffs to weigh. Examples: missing-argument errors, invalid-argument-type errors, ruff/lint fixes, import errors. Go directly to the fix.
- If the fix turns out to require a real design decision (e.g. the type error reveals a genuine model bug), pause and re-enter the brainstorm flow at that point.

## References

| Topic         | Reference                     | When                                      |
| ------------- | ----------------------------- | ----------------------------------------- |
| Testing       | `references/testing.md`       | Defining expected behaviors as test cases |
| Writing Plans | `references/writing-plans.md` | How to write plans for implementation     |

## Workflow

You MUST create a task for each of these items and complete them in order:

- Explore project context - check files. **Look for sibling/reference implementations** in this repo or related repos (e.g. how does `vol_surface` / `product_surface` / `rv-utils` solve the same shape of problem?). Reading them up front prevents reinventing patterns. **But do not accept them at face value** — for each pattern you'd borrow, ask "why did they do it that way, and does that reason apply here?" If the answer is "because X does it this way," that's not a justification. Expect to argue the pattern's merits before adopting it.
- Ask clarifying questions - one at a time, understand purpose/constraints/success criteria. **Default to prose questions.** Reserve `AskUserQuestion` (multi-option picker with previews) for moments where the user is at a decision point between 2-4 mutually exclusive concrete paths, not still exploring. Reaching for the picker too early commits to a frame ("here are the options") before the user has decided what shape the answer should take.
- Present suggested approach - talk about tradeoffs and if there are any other possible approaches that have different tradeoffs
- Define expected behaviors as tests - focus on **core behaviors only**: what must be true for the feature to be correct? Aim for 3–5 entries that would catch a broken implementation. Skip edge cases and style assertions unless the feature is inherently complex (stateful multi-step flows, parsing, data transformations). Use `references/testing.md` format. Get user approval before proceeding — this approval can be combined with the "transition to implementation" step if the list is short and uncontroversial.
- Write design doc - save to `cwd/docs/DESIGN.md`
- Spec self-review - quick inline check for placeholders, contradictions, ambiguity, scope (see below)
- User reviews written spec - ask user to review the spec file before proceeding
- Transition to implementation with a plan — see the `writing-plans` doc in `references/writing-plans.md` for what it produces
  - start with the design doc previously made and the tests that were previously defined and approved
  - Once the plan is saved, **default to running all tasks end-to-end without pausing for review between them**. Each task follows TDD (test red → implement → test green → make fmt/check/test passing) but you don't stop between tasks. Pause once at the end for a single review covering the full plan. Don't poll the user with AskUserQuestion about execution mode — they have already approved the plan. Only deviate from inline-all-at-once if the user explicitly asks for a different mode (subagent-driven, per-task pause) or if the plan is large enough that fresh subagents per task are obviously needed.
  - **Within a task, don't stop in the middle either.** Don't pause after writing the failing test to ask if you should implement, and don't pause after implementing to ask if you should run tests. Run each task TDD-cycle straight through.
