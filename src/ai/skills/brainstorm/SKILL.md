---
name: brainstorm
description: 'Use before creative implementation with real design space: features, components, scripts/tools, system designs, or proposal planning. Also trigger on "grill me", "stress-test this", and "interview me". Challenge the premise, ask one question at a time with a recommended answer, define expected behaviors, and get approval before coding. Skip direct concrete edits, mechanical type/build/lint fixes, throwaway experiments, and handoff summaries.'
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

## Exception: user is already steering a concrete change

- Skip brainstorm when the user is directly directing a specific change with no design space to explore ("use format X", "switch to Y", "actually do Z instead"). They've already done the design thinking. Ask a targeted question if anything is ambiguous, then make the change.

## Exception: throwaway experiment or context handoff

- Skip when the user just wants to *try something out* — a throwaway probe, a `tmp/` experiment, a "let me see if this works" spike with no intent to ship. Design process on a disposable experiment is friction with no payoff. If the experiment graduates to real work, re-enter the flow then.
- Skip when the user wants a **context handoff or summary for another agent/session** ("write up what we did so another Claude can pick this up", "summarize the state for a handoff"). That's a documentation task, not a design task — produce the handoff, don't run the DESIGN.md workflow.

## References

| Topic         | Reference                     | When                                      |
| ------------- | ----------------------------- | ----------------------------------------- |
| Testing       | `references/testing.md`       | Defining expected behaviors as test cases |
| Writing Plans | `references/writing-plans.md` | How to write plans for implementation     |

## Workflow

You MUST create a task for each of these items and complete them in order:

- Explore project context - check files. **Look for sibling/reference implementations** in this repo or related repos (e.g. how does `vol_surface` / `product_surface` / `rv-utils` solve the same shape of problem?). Reading them up front prevents reinventing patterns. **But do not accept them at face value** — for each pattern you'd borrow, ask "why did they do it that way, and does that reason apply here?" If the answer is "because X does it this way," that's not a justification. Expect to argue the pattern's merits before adopting it.
  - **Verify the rails the design will stand on, don't assume them.** Two recurring misses: (1) designing a new field/column/plumbing path when an existing one already carries the value — grep for the canonical field first (`listing`, `name`, `ns`, etc.). (2) designing on top of a claim like "downstream X handles entity Y" or "this value has one consumer" — read X's actual code path and trace every consumer before building on it. A design doc that asserts an existing-rails fact it never checked is the same bug as a load-bearing tradeoff left unverified.
  - **Anchor on committed state, not in-conversation edits.** Before writing a design or plan, confirm the branch's actual committed state — earlier edits in this conversation, a teammate's merge, or a reset may have moved it. Don't design against a phantom state you only believe is live.
- Grill the design - this is the default phase before any coding, and the heart of the skill. Interview the user **relentlessly** about every aspect of the plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one (answer the decision an upstream choice depends on before the choices that hang off it). Don't stop at the first layer of questions; keep going until there's nothing load-bearing left unresolved.
  - **For each question, provide your recommended answer** and the reasoning, so the user is reacting to a concrete proposal rather than facing an open void. "I'd do X because Y — agree, or do you see it differently?"
  - **Ask one question at a time, and wait for the answer before the next.** Asking multiple at once is bewildering and tanks the quality of each answer. This is non-negotiable.
  - **If a question can be answered by exploring the codebase, explore instead of asking.** Don't make the user tell you what a grep or a file read would reveal. Reserve questions for genuine decisions and preferences only you can't derive.
  - **Default to prose questions.** Reserve `request_user_input` when available for moments where the user is at a decision point between 2-4 mutually exclusive concrete paths, not still exploring. Reaching for the picker too early commits to a frame ("here are the options") before the user has decided what shape the answer should take.
  - **Collapse scope the moment grilling reveals the work is small.** If the interview resolves the task down to a few constants, a single guard, or a config edit with no real design forks, stop running the heavy workflow: skip the DESIGN.md/test-definition machinery, state the change in a sentence, and confirm. The full workflow is for genuine design space; don't spend it on what shrank to a mechanical edit. (This is the entry-time version of the implementation fast-path below.)
- Present suggested approach - talk about tradeoffs and if there are any other possible approaches that have different tradeoffs. **When the answer covers multiple features (e.g. user picked "all of the above"), surface the design cost of each before committing — treat it as a menu, not a contract.** **Verify load-bearing assumptions, don't just list them.** If a tradeoff is phrased "X is true in practice" / "true for the products we care about" / "shouldn't happen" AND the design's correctness depends on it, treat it as a TODO, not an accepted risk: verify it cheaply (refdata query, grep, doc check) if you can, otherwise design as if it's false and check the design still holds. The smell is present-tense "is true" (a fact to check) vs "we accept that" (a real tradeoff). Real miss: a "futures of the same product share point_value — true in practice" tradeoff was load-bearing and false for EU gas (TTF contract size varies by delivery month), which broke the implementation.
- Define expected behaviors as tests - focus on **core behaviors only**: what must be true for the feature to be correct? Aim for 3–5 entries that would catch a broken implementation. Skip edge cases and style assertions unless the feature is inherently complex (stateful multi-step flows, parsing, data transformations). Use `references/testing.md` format. **Before presenting, ask for each test: is this behavior already exercised by another test in the list or by existing infrastructure? Drop redundant tests before presenting.** Get user approval before proceeding — this approval can be combined with the "transition to implementation" step if the list is short and uncontroversial.
- Write design doc - save to `cwd/docs/DESIGN.md`
- Spec self-review - quick inline check for placeholders, contradictions, ambiguity, scope (see below)
- User reviews written spec - ask user to review the spec file before proceeding
- Transition to implementation with a plan — follow the format in `references/writing-plans.md` to produce a step-by-step plan
  - **Fast-path for clearly-bounded changes:** when the implementation is small and unambiguous after design approval (e.g. one guard clause + N tests, a single-function edit, ≤2 files), skip the separate plan file — the approved design doc already captures the intent. Go straight to TDD. Reserve the full plan file for multi-step or multi-file work where the sequencing isn't obvious. When in doubt, ask "is the plan file telling the user anything the design doc didn't?" — if no, skip it.
  - start with the design doc previously made and the tests that were previously defined and approved
  - Once the plan is saved, **stop and hand off.** The user drives implementation — don't auto-execute tasks. Wait for them to direct specific steps ("go ahead with task 1", "implement this"). Only execute if they explicitly say so.
  - When executing a task: follow TDD (test red → implement → test green → make fmt/check/test passing). **Don't stop in the middle of a task** — run the full TDD cycle straight through without pausing to ask if you should continue.
