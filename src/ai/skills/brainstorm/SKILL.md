---
name: brainstorm
description: 'Use before creative implementation with real design space: features, components, scripts/tools, system designs, or proposal planning. Also trigger on "grill me", "stress-test this", and "interview me". Challenge the premise, ask one question at a time with a recommended answer, define expected behaviors, and get approval before coding. Skip direct concrete edits, mechanical type/build/lint fixes, throwaway experiments, and handoff summaries.'
---

# Brainstorming

- Help turn ideas into fully formed designs and specs through natural collaborative dialogue.
- Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.
- Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. Perceived simplicity is not an exception on its own — see the named Exceptions below for the actual carve-outs.

## Challenge the premise first

Before going deep on design, sanity-check the work itself. The user often has a thread to pull but hasn't decided whether the work is worth doing — your job is to surface that, not to assume it.

- Is the request redundant with an existing system? (e.g. "double-alert in addition to the upstream alert" — what failure mode does the new copy actually catch?)
- Is the user's framing the right one, or is there a simpler interpretation of their goal?
- Is there an existing solution they don't know about?

If the premise looks shaky, raise it early — before clarifying questions, not after design. A short "before we go deep, here's what I'd push back on…" is cheaper than a full design that ends with the user saying "actually, should we even do this?"

## Exception: type-checker / build-fix passthrough

- Skip the brainstorm workflow entirely when the task is purely "make ty/mypy happy" or "make the build pass" with **no behavior change and no design choice** — there's a wrong type and a right type, no tradeoffs to weigh. Examples: missing-argument errors, invalid-argument-type errors, ruff/lint fixes, import errors. Go directly to the fix.
- If the fix turns out to require a real design decision (e.g. the type error reveals a genuine model bug), pause and re-enter the brainstorm flow at that point.

## Exception: user is already steering a concrete change

- Skip brainstorm when the user is directly directing a specific change with no design space to explore ("use format X", "switch to Y", "actually do Z instead"). They've already done the design thinking. Ask a targeted question if anything is ambiguous, then make the change.

## Exception: throwaway experiment or context handoff

- Skip when the user just wants to *try something out* — a throwaway probe, a `tmp/` experiment, a "let me see if this works" spike with no intent to ship. Design process on a disposable experiment is friction with no payoff. If the experiment graduates to real work, re-enter the flow then.
- Skip when the user wants a **context handoff or summary for another agent/session** ("write up what we did so another session can pick this up", "summarize the state for a handoff"). That's a documentation task, not a design task — produce the handoff, don't run the visual plan workflow.

## Local Visual Plan Artifact

Use a self-contained local visual plan as the user-facing design artifact when the work has real design space. Read `references/visual-plan.md` in full — it owns the self-contained contract, the MDX component library, and the validation/serving steps. One rule that lives only here: the visual plan is for design approval; `tmp/PLAN.md` (written later, see Workflow below) is for implementation sequencing — keep the two separate.

## References

| Topic              | Reference                            | When                                      |
| ------------------ | ------------------------------------ | ----------------------------------------- |
| Testing            | `references/testing.md`              | Defining behavior contracts and deciding verification |
| Writing Plans      | `references/writing-plans.md`        | How to write plans for implementation     |
| Local Visual Plans | `references/visual-plan.md`          | Authoring self-contained local plans      |
| Exemplar           | `references/exemplar.md`             | Calibrating good vs bad visual plans      |

## Workflow

Follow these phases in order:

### Model routing

- Keep discovery, grilling, design, behavior contracts, plan authoring, and plan review in the primary thread on the user's selected model and reasoning effort. Do not delegate planning to a cheaper model.
- After design approval, delegate nontrivial implementation to one implementation-focused subagent using `gpt-5.6-terra` with `medium` reasoning when the host supports explicit subagent model overrides. Give it the approved visual plan, implementation plan when present, exact behavior contract, and instruction to edit the working tree and run the relevant tests.
- Keep a clearly mechanical edit in the primary thread when spawning an agent would cost more than the work. If delegation is unavailable, implement in the primary thread rather than blocking.
- The primary thread owns acceptance: inspect the worker's complete diff, verify it implemented the approved design, run the real test suite rather than only static checks, and send defects back to the same worker when practical. Do not accept a worker's summary as verification.

- Explore project context - check files. **Look for sibling/reference implementations** in this repo or related repos (e.g. how does `vol_surface` / `product_surface` / `rv-utils` solve the same shape of problem?). Reading them up front prevents reinventing patterns. **But do not accept them at face value** — for each pattern you'd borrow, ask "why did they do it that way, and does that reason apply here?" If the answer is "because X does it this way," that's not a justification. Expect to argue the pattern's merits before adopting it.
  - **Verify the rails the design will stand on, don't assume them.** Two recurring misses: (1) designing a new field/column/plumbing path when an existing one already carries the value — grep for the canonical field first (`listing`, `name`, `ns`, etc.). (2) designing on top of a claim like "downstream X handles entity Y" or "this value has one consumer" — read X's actual code path and trace every consumer before building on it. A visual plan that asserts an existing-rails fact it never checked is the same bug as a load-bearing tradeoff left unverified.
  - **Anchor on committed state, not in-conversation edits.** Before writing a design or plan, confirm the branch's actual committed state — earlier edits in this conversation, a teammate's merge, or a reset may have moved it. Don't design against a phantom state you only believe is live.
  - **Locate unions at the right level.** When modeling a collection, verify whether one value may mix variants or whether each value is homogeneous and only the collection type varies. Preserve `Mapping[A, V] | Mapping[B, V]` when each mapping contains exactly one key type; use `Mapping[A | B, V]` only when mixed keys are valid. Introduce a generic only when an API must preserve a key-type relationship that the direct union cannot express.
  - **Trace conventions end to end before designing conversions.** For prices, vols, times, symbols, and other convention-heavy values, record the source unit/meaning, each transformation, the consumer's expected unit/meaning, and the production configuration that selects the path. Verify external-library behavior from its docs or a focused probe, and verify desk-specific semantics with the owning desk when code cannot settle them. A passing number after a magic scale factor is not evidence that the conversion is right.
- Grill the design - this is the default phase before any coding, and the heart of the skill. Interview the user **relentlessly** about every aspect of the plan until you reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one (answer the decision an upstream choice depends on before the choices that hang off it). Don't stop at the first layer of questions; keep going until there's nothing load-bearing left unresolved.
  - **For each question, provide your recommended answer** and the reasoning, so the user is reacting to a concrete proposal rather than facing an open void. "I'd do X because Y — agree, or do you see it differently?"
  - **Ask one question at a time, and wait for the answer before the next.** Asking multiple at once is bewildering and tanks the quality of each answer. This is non-negotiable.
  - **If a question can be answered by exploring the codebase, explore instead of asking.** Don't make the user tell you what a grep or a file read would reveal. Reserve questions for genuine decisions and preferences only you can't derive.
  - **Default to prose questions.** Reserve `request_user_input` when available for moments where the user is at a decision point between 2-4 mutually exclusive concrete paths, not still exploring. Reaching for the picker too early commits to a frame ("here are the options") before the user has decided what shape the answer should take.
  - **Collapse scope the moment grilling reveals the work is small.** If the interview resolves the task down to a few constants, a single guard, or a config edit with no real design forks, stop running the heavy workflow: skip the visual plan/test-definition machinery, state the change in a sentence, and confirm. The full workflow is for genuine design space; don't spend it on what shrank to a mechanical edit. (This is the entry-time version of the implementation fast-path below.)
- Present suggested approach - talk about tradeoffs and if there are any other possible approaches that have different tradeoffs. **When the answer covers multiple features (e.g. user picked "all of the above"), surface the design cost of each before committing — treat it as a menu, not a contract.** **Verify load-bearing assumptions, don't just list them.** If a tradeoff is phrased "X is true in practice" / "true for the products we care about" / "shouldn't happen" AND the design's correctness depends on it, treat it as a TODO, not an accepted risk: verify it cheaply (refdata query, grep, doc check) if you can, otherwise design as if it's false and check the design still holds. The smell is present-tense "is true" (a fact to check) vs "we accept that" (a real tradeoff). Real miss: a "futures of the same product share point_value — true in practice" tradeoff was load-bearing and false for EU gas (TTF contract size varies by delivery month), which broke the implementation.
- Make the mechanism concrete before presenting files. Name the durable unit of work, success, failure/retry, and ordering. For stateful, concurrent, or partial-failure designs, walk through the smallest example that distinguishes the proposed behavior from the current behavior.
- Map failure boundaries when errors can be handled at different scopes. Use `BoundaryMatrix` to show the failure, handling scope, and why that scope is safe. Do not imply partial recovery when identity or ordering is no longer trustworthy.
- Define the behavior contract and verification - focus on **core behaviors only**: what must be true for the feature to be correct? Aim for 3–5 entries for genuinely complex work; use fewer when that is all the design needs. Classify each entry as a new `test`, an `invariant` that should shape the design without another test, or a `manual check`. For every manual artifact, state what visible fact distinguishes success from the old behavior; a screenshot or benchmark with no discriminating observation proves nothing. Use `references/testing.md` for the format and selection rules. **Do not turn every desired behavior into a test.** Existing framework validation, types, stronger tests, and runtime measurements often make another test redundant. Get user approval before proceeding; this approval can be combined with the transition to implementation when the contract is short and uncontroversial.
- Write local visual plan - read `references/visual-plan.md` in full. Create `<plan-dir>/plan.mdx` per that reference. This is the user-facing review gate. Include the approved approach, tradeoffs, expected behaviors, performance boundaries, file map, and open questions.
- Spec self-review - inspect `plan.mdx` and the rendered output for placeholders, contradictions, ambiguity, scope drift, broken anchors, and missing sections. If a repo-native MDX checker exists, run it; do not install one.
- User reviews visual plan - report the verified rendered URL, local `plan.mdx` path, and plan folder path, then ask the user to review the visual plan before proceeding.
- Transition to implementation with a Markdown plan - follow the format in `references/writing-plans.md` to produce a step-by-step plan for the agent.
  - **Fast-path for clearly-bounded changes:** when the implementation is small and unambiguous after design approval (e.g. one guard clause + N tests, a single-function edit, ≤2 files), skip the separate plan file — the approved visual plan already captures the intent. Go straight to TDD. Reserve the full plan file for multi-step or multi-file work where the sequencing isn't obvious. When in doubt, ask "is the Markdown plan telling the user anything the visual plan didn't?" — if no, skip it.
  - start with the approved local visual plan and implement only the entries classified as new tests
  - Save the implementation plan to `cwd/tmp/PLAN.md` unless the fast-path rule above makes a separate file redundant. The confirmation gate is the visual plan, not this file: once the user has approved the visual plan, saving the Markdown plan does not require a second approval — proceed straight into execution unless the user asked to review the Markdown plan first or the implementation diverges from what the visual plan described.
  - When executing a task: follow TDD (test red → implement → test green → make fmt/check/test passing). **Don't stop in the middle of a task** — run the full TDD cycle straight through without pausing to ask if you should continue.
  - **Before calling a test green, re-check the assertion you actually wrote against `GLOBAL.md`'s "Recurring bad-test patterns."** The approved `what`/`why` from the design step describes intent; it doesn't guarantee the assertion you end up writing during TDD is real. This is where tautological and vacuous tests actually creep in — a hand-approved plan doesn't stop you from later writing `assert result == (a - b) / (c - d)` for a function that computes exactly that. Check it at the point the assertion is written, not just at plan approval.
  - **Bring down the MDX visual-plan server the moment execution starts.** Once the user approves and asks to implement, the plan is no longer the live review surface — kill the `serve-mdx-visual-plan` / vite process (`pkill -f serve-mdx-visual-plan`) so it isn't left running for the rest of the session. The `plan.mdx` file stays on disk for reference; only the server comes down.
