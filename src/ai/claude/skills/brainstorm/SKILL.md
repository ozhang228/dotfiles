---
name: brainstorm
description: You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation.
allowed-tools: Read, Grep, Glob
---

# Brainstorming

- Help turn ideas into fully formed designs and specs through natural collaborative dialogue.
- Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.
- Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.

## Anti-Pattern: "This Is Too Simple To Need A Design"

- Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## References

| Topic         | Reference                     | When                                      |
| ------------- | ----------------------------- | ----------------------------------------- |
| Testing       | `references/testing.md`       | Defining expected behaviors as test cases |
| Writing Plans | `references/writing-plans.md` | How to write plans for implementation     |

## Workflow

You MUST create a task for each of these items and complete them in order:

- Explore project context - check files / ai wiki (`$HOME/forge/ai_wiki/`)
- Ask clarifying questions - one at a time, understand purpose/constraints/success criteria
- Present suggested approach - talk about tradeoffs and if there are any other possible approaches that have different tradeoffs
- Define expected behaviors as tests - using `references/testing.md` format, produce a list of `test_<name> / why:` entries that describe what the feature must do. Get user approval on this list before proceeding. These become the test plan for implementation.
- Write design doc - save to `cwd/docs/DESIGN.md`
- Spec self-review - quick inline check for placeholders, contradictions, ambiguity, scope (see below)
- User reviews written spec - ask user to review the spec file before proceeding
- Transition to implementation with a plan — see the `writing-plans` doc in `references/writing-plans.md` for what it produces and the execution options it will offer
  - start with the design doc previously made and the tests that were previously defined and approved
