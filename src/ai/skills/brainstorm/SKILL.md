---
name: brainstorm
description: 'Use before creative implementation with real design space: features, components, scripts/tools, system designs, or proposal planning. Also trigger on "grill me", "stress-test this", and "interview me". Challenge the premise, ask one question at a time with a recommended answer, define expected behaviors, and get approval before coding. Skip direct concrete edits, mechanical type/build/lint fixes, throwaway experiments, and handoff summaries.'
---

# Brainstorming

- Help turn ideas into fully formed specs through collaborative dialogue.
- Understand the current project context, then ask questions one at a time to refine the idea. Afterwards, present the design and get user approval.
- Skip the brainstorm workflow when the task is purely "fix build issue" **no behavior change and no design choice** 
- Skip when the user just wants to *try something out* — a throwaway probe, a `tmp/` experiment, a "let me see if this works" spike with no intent to ship. 

## Challenge the premise first

Before design, sanity-check the work itself. The user often has a thread to pull but hasn't decided whether the work is worth doing, surface that 

- Is the request redundant with an existing system? 
- Is the user's framing the right one, or is there a simpler interpretation of their goal?
- Is there an existing solution they don't know about?

If the premise looks shaky, raise it early. 

## References

| Topic              | Reference                            | When                                      |
| ------------------ | ------------------------------------ | ----------------------------------------- |
| Testing            | `references/testing.md`              | Defining behavior contracts and deciding verification |
| Writing Plans      | `references/writing-plans.md`        | How to write plans for implementation     |
| Local Visual Plans | `references/visual-plan.md`          | Authoring self-contained local plans      |
| Structured Blocks  | `references/structured-blocks.md`    | Component library (shared with `code-review`) |

## Workflow

Follow these phases in order:

### Model routing

- Keep discovery, grilling, design, behavior contracts, plan authoring, and plan review in the primary thread on the user's selected model and reasoning effort. Do not delegate planning to a cheaper model.
- After design approval, delegate nontrivial implementation to one implementation-focused subagent using `gpt-5.6-terra` with `medium` reasoning. Give it the approved visual plan, implementation plan when present, exact behavior contract, and instruction to edit the working tree and run the relevant tests.
- Keep a clearly mechanical edit in the primary thread when spawning an agent would cost more than the work. If delegation is unavailable, implement in the primary thread rather than blocking.
- The primary thread owns acceptance: inspect the worker's complete diff, verify it implemented the approved design, run the test suite and static checks, and send defects back to the same worker when practical. Do not accept a worker's summary as verification.

- Explore project context - check files. Look for sibling/reference implementations in user repos. Do not accept them at face value, for each pattern you'd borrow, ask "why did they do it that way, and does that reason apply here?" If the answer is "because X does it this way," that's not a justification. Expect to argue the pattern's merits before adopting it.
  - Verify the rails the design will stand on, don't assume them. Two recurring misses: (1) designing a new field/column/plumbing path when an existing one already carries the value — grep for the canonical field first. (2) designing on top of a claim like "downstream X handles entity Y" or "this value has one consumer" — read X's actual code path and trace every consumer before building on it. 
- Grill the design, this is the default phase before any coding. Interview the user about every aspect of the plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one (answer the decision an upstream choice depends on before the choices that hang off it). Don't stop at the first layer of questions; keep going until there's nothing load-bearing left unresolved.
  - If a question can be answered by exploring the codebase, explore instead of asking.
  - For each question, provide your recommended answer and the reasoning, so the user is reacting to a concrete proposal 
  - Ask one question at a time, and wait for the answer before the next.
  - Default to prose questions instead of requesting user input. 
  - Collapse scope the moment grilling reveals the work is small. Don't run the whole workflow for a trivial change
- Present suggested approach - talk about tradeoffs and if there are any other possible approaches that have different tradeoffs. 
- Make the mechanism concrete before presenting files. Name the durable unit of work, success, failure/retry, and ordering. For stateful, concurrent, or partial-failure designs, walk through the smallest example that distinguishes the proposed behavior from the current behavior.
- Map failure boundaries when errors can be handled at different scopes. Use a `boundary-matrix` block to show the failure, handling scope, and why that scope is safe. Do not imply partial recovery when identity or ordering is no longer trustworthy.
- Define the behavior contract and verification - focus on **core behaviors only**: what must be true for the feature to be correct? Aim for 3–5 entries for genuinely complex work; use fewer when that is all the design needs. Classify each entry as a new `test`, an `invariant` that should shape the design without another test, or a `manual check`. For every manual artifact, state what visible fact distinguishes success from the old behavior; a screenshot or benchmark with no discriminating observation proves nothing. Use `references/testing.md` for the format and selection rules. **Do not turn every desired behavior into a test.** Existing framework validation, types, stronger tests, and runtime measurements often make another test redundant. Get user approval before proceeding
- Write local visual plan - read `references/visual-plan.md` in full. Create `tmp/plan.html` per that reference. Include the approved approach, tradeoffs, expected behaviors, performance boundaries, file map, and open questions.
- Spec self-review - inspect `plan.html` and `plan.md` for placeholders, contradictions, ambiguity, scope drift, broken anchors, and missing sections.
- User reviews visual plan - report the served URL then ask the user to review the visual plan before proceeding.
- Transition to implementation with a Markdown plan - follow the format in `references/writing-plans.md` to produce a step-by-step plan for the agent.
  - start with the approved local visual plan and implement only the entries classified as new tests
  - Save the implementation plan to `cwd/tmp/PLAN.md`. Once the user has approved the visual plan, saving the Markdown plan does not require a second approval — proceed straight into 
  - When executing a task: follow TDD (test red → implement → test green → make fmt/check/test passing). **Don't stop in the middle of a task** — run the full TDD cycle straight through without pausing to ask if you should continue.
  - Bring down the local plan server the moment execution starts.
