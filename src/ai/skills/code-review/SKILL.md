---
name: code-review
description: Review PRs, diffs, and uncommitted code changes, or produce a guided file:line reading tour when asked to explain how code works. Use for code review, PR review, code quality audits, refactoring suggestions, security checks, "explain how X works", and "walk me through Y".
---

# Code Review

You own the review: explain the PR to the user in reading order, not just a bug list. Do the deep investigation pass yourself, gate on architecture direction, then run up to four focused line-level review passes. Use host delegation if it exists; otherwise run the passes yourself. Merge and validate everything before showing it to the user.

**No diff to review?** Same skill, pointed at an existing system/feature/concept instead of a PR ("explain how X works", "walk me through the auth flow"). Skip merge-base resolution, the architecture gate, focused review passes, and the Bugs/Testing/Performance/Simplification sections. Identify prerequisites (invariants, vocabulary, abstractions the code assumes), write `## Prerequisites` then `## Reading Tour` with ordered `file:line` stops, each explaining what to look for, with opinions inline (confusing naming, whether files live under their conceptual owner, a better structure, why it's built this way). End by inviting the user to read and come back with questions. Push toward a verdict ("does this design make sense to you?", "what would you do differently?"), not just comprehension. Length follows the concept: 3 stops or 12. Give `file:line` anchors, not large pasted snippets.

## Reference Guide

Run the bundled `scripts/pr-languages` first to identify which languages are in the diff, then load the relevant language references below. Invoke it from this skill directory or by its resolved filesystem path so it works from any repo CWD.

| Topic             | Reference                         | When                                  |
| ----------------- | --------------------------------- | ------------------------------------- |
| Python            | `references/python.md`            | Any `.py` files in the diff           |
| TypeScript/TSX    | `references/typescript.md`        | Any `.ts` or `.tsx` files in the diff |
| Feedback Examples | `references/feedback-examples.md` | Writing good feedback                 |
| Local Recaps      | `references/visual-recap.md`      | Authoring self-contained local recaps |
| Structured Blocks | `references/structured-blocks.md` | Diff, API, boundary, and navigation components (shared with `brainstorm` - see that file's header) |

## Review Workflow

Four phases: **you alone** investigate (1) and gate on architecture (2); then run up to four focused review passes (3) and merge what they return (4). Investigation happens once, in the main thread; hand focused passes what they need instead of letting them repeat it.

### Phase 1 — Investigation (main thread only)

This is the single deep pass over the PR. Do all of it before spawning anything.

1. **Confirm the repo/branch matches the user's active context.** Surface any mismatch before proceeding.
2. **Diff against the merge base, not the moving base branch tip.** Resolve the review base with `git -C <repo> merge-base <base> HEAD` and use that SHA for `git diff`, `git diff --stat`, and changed-file discovery. Note if the branch is behind `<base>`, but do not stop to ask about merging unless the user explicitly asked for an up-to-date integration review.
3. Run the bundled `scripts/pr-languages` by resolved filesystem path. Note which language references (`references/python.md`, `references/typescript.md`) apply; load them yourself for the architecture verdict and pass them to any delegated review.
4. Do a git diff against the merge-base SHA pr-languages resolved (unless another branch or base SHA is specified).
5. Read full files and related files for context. Record exact `file_path:line` ranges for the changed surface for focused passes to use.
6. **Read the tests first.** Flag any expected behavior that looks weird, surprising, or wrong before looking at the implementation, then check the implementation against it.
7. Identify the durable units of work, success, failure/retry, and ordering. For stateful, concurrent, or partial-failure changes, construct the smallest concrete scenario that distinguishes old from new behavior before reading the implementation as a file list.
8. **Audit scope before details.** Classify every hunk as core behavior, required support, or incidental. Flag wrappers with one caller, duplicate fields or code paths, generalized types without a second valid case, no-op rewrites, and noisy config/format churn. If the diff contains independently reviewable behavior, recommend a causal split before reviewing the combined implementation.
9. **Audit file ownership and repository structure.** For every added or moved file, decide whether the capability belongs in this repository, package, and module; whether its directory makes the conceptual owner obvious; and whether an existing owner should be extended instead. Compare sibling placement and test colocation. Use import direction and cycle avoidance as tie-breakers, not as the primary placement rationale.
10. **Audit local consistency.** For adjacent branches or expressions implementing the same concept, match the existing syntax and structure unless a semantic difference requires divergence.
11. **Audit conventions dimensionally.** For every conversion involving prices, vols, rates, ticks, currency, time, or dates, trace source units through each operation to the consumer. Treat unexplained scale factors and inferred desk conventions as correctness risks even when tests pass. Check external-library semantics and production configuration rather than inferring them from stubs.

### Phase 2 — Architecture gate (hard block)

Before any line-level review, decide whether the PR is going the right way. Write to the chat:

- **"The PR is solving X"** — your one-line understanding of intent.
- **An architecture / modeling verdict.** Is this the right approach? The right data model? Challenge implicit assumptions. Commit to a verdict — "I think the approach is sound" or "I'd push back, because Y" — not just a description of what the code does.
- **A file structure / ownership verdict.** Do new or moved files belong in this repository, package, module, and directory? Does the structure make ownership discoverable? Name any move or colocation needed.
- **A scope verdict.** Is this one coherent review unit, or are unrelated behavior, speculative abstraction, and cleanup making the PR harder to validate? Name the split if one is needed.
- **A boundary verdict when failure scopes differ.** State which failures can be isolated and which invalidate the wider operation, and whether the code has enough identity/order information to make that distinction safely.

Then **stop and wait for the user to confirm the direction.** Do not run focused line-level passes or write comments until they confirm. If they want a different approach, re-scope first.

### Phase 3 — Focused passes (only after confirmation)

Run up to four focused passes, each focused on exactly one thing. Use the host's delegation mechanism if it exists; if not, do the same passes in the main thread and record that delegation was unavailable. **You decide which passes to run**: skip a pass with no surface area (a docs/config-only PR skips Performance; a pure refactor with full existing coverage may skip Testing; a one-line bugfix skips Simplification) and record the skip + reason for the report. Run delegated passes in parallel when the host supports it.

Review work must retain the primary thread's selected model and reasoning quality. When delegating a focused review pass, inherit the parent model and effort; do not route review, architecture, finding validation, or recap synthesis to the cheaper implementation model.

Each delegated reviewer gets a **context packet** so it doesn't re-investigate:

- the "PR is solving X" summary and your confirmed architecture verdict
- the exact file list + `line` ranges to review (the delegated reviewer reads only what you point it at)
- which language reference to load for those files (`references/python.md` / `references/typescript.md`) — tell it to read that file first
- the return contract below

Use host-native file and shell tools inside delegated prompts. Describe the operation to perform, not a product-specific tool name: read files, search with `rg`, and run shell commands when needed.

The four passes:

| Pass            | Sole focus                                            | Must do |
| --------------- | ----------------------------------------------------- | ------- |
| **Correctness** | Will this run as expected?                            | For each finding, give a **concrete triggering input** + expected-vs-actual behavior. Re-trace the path. If it can't construct a failure case, the bug isn't real, drop it or downgrade to a question. |
| **Testing**     | Do tests document each function's behavior, and are the tests in the diff themselves correct? | Two jobs. **(a) Gaps:** map every changed function to the test(s) that pin its behavior; for each gap, **propose a concrete test as a code block**. For non-obvious tests, explain the causal oracle: what broken implementation would make the assertion fail, deadlock, or time out. **(b) Review the added/changed tests themselves** against our testing contract. Every test must exercise and assert public, observable behavior; do not test private helpers, cache keys, internal state, call routing, or another implementation mechanism. For every added test, identify the production defect it uniquely catches. When practical, prove necessity with a mutation check: revert or bypass the relevant production hunk, run the closest existing tests without the new test, then run the new test. If an existing test already fails for the same defect, keep the clearer behavior-level test and remove the redundant coverage; if only the new test fails, retain it. Test names must also describe the observable behavior. Assertions must match the exact semantic (`assert x == expected`, not `assert x` / `assert len(x)` / `assert x is not None` when the real contract is a specific value); flag over-parametrized cases that add no new branch; no fixtures, mocks, or test classes (see `references/python.md`). It proposes and critiques; it does **not** write files. |
| **Performance** | Easy wins that limit performance                      | Only report a win it **validated with a small benchmark**. Include the command and before/after absolute numbers. An unbenchmarked hunch is dropped or downgraded to a question. Reason through the allocation/call model; "looks cleaner" is not "faster". |
| **Simplification** | What in this diff is over-engineered and can be cut?  | First audit every hunk against the PR's core behavior. Flag incidental lint cleanup, equivalent refactors, and any other change that can be reverted without affecting that behavior. Hunt only complexity to delete, never correctness/security/perf. One finding per line, each tagged: `delete:` (dead code, unrelated diff hunks, unused flexibility, speculative feature, replacement is nothing), `stdlib:` (hand-rolled thing the standard library ships, name the function), `native:` (dep or code doing what the platform already does, name the feature), `yagni:` (abstraction with one implementation, config nobody sets, layer with one caller), `shrink:` (same logic, fewer lines, show the shorter form). **Readability is a hard floor:** never propose a `shrink:` that trades clarity for line count; a denser one-liner that's harder to read is not a win, drop it. **Never flag the single smoke test or `assert`-based self-check for deletion**, that's the minimum, not bloat. End its return with `net: -<N> lines possible`. If nothing holds up, it returns `Lean already.` and no findings. |

**Return contract** — each pass returns a flat list of findings, no prose padding. Each finding: `file_path:line`, a one-line claim, a severity, and **either** old/new code blocks **or** a specific question the author must answer. Performance findings additionally carry the benchmark command + before/after numbers. Simplification findings carry the tag + the replacement (or `net: -<N> lines possible` at the end).

### Phase 4 — Merge + validate (main thread)

The focused passes find; you decide what survives.

- **Validate every finding before accepting it.** Re-trace correctness claims against the code you already read. Confirm proposed tests target genuine gaps. Sanity-check that perf numbers are plausible and the benchmark measured the right thing. Drop or downgrade anything that doesn't hold up.
- **Close delegated reviewers once their results are merged** if the host provides a close mechanism.
- **Drop functionally-equivalent rewrites** — same logic, different spelling, no clearer to read. Before accepting any simplification/nit, ask "does this change behavior, fix a bug, or materially improve readability?" If not, cut it; don't relay it to the user.
- **Dedup across passes.** If two passes flag the same line, write one comment.
- **Add style nits yourself.** Naming, clarity, dead code, conventions.

## Resolving review comments (author side)

When the work is the reverse — you're the author addressing comments on your own PR, not producing a review — apply these rules:

- **Route implementation separately from review.** The primary thread verifies the comment's premise and decides the fix. For a nontrivial accepted fix, delegate implementation to one subagent using `gpt-5.6-terra` with `medium` reasoning, providing the validated finding, expected behavior, exact repository scope, and required tests. Keep tiny mechanical edits local. Afterward, inspect the complete diff and run the real tests in the primary thread; send defects back to the same worker when practical.

- **Verify the comment's premise before agreeing or building.** "Use `strikes_from_sds`", "isn't there an outright type for this?", "X already does it this way" are premises, not facts. Grep for the type, read the helper, check what the sibling actually does — *then* act. This holds for pushback too: verify before you defend.
- **Lead placement decisions with ownership, not the import graph.** When a comment is "this doesn't belong here," decide where a thing lives by *what conceptually owns it* (a port belongs with its consumer; an interface with its domain), then use cycle-avoidance to break ties — never let "what imports cleanly" drive the call.
- **Branch hygiene under concurrent pushes.** When the author (you or Oscar) may be pushing in parallel, re-check `HEAD` vs `origin/<branch>` before every commit and push. A published merge commit must never be amended. Land each fix on the PR/branch that *owns* the file it touches, not whichever branch is checked out.
- **Re-audit every stacked PR after history rewrites.** Inspect each branch's exact merge-base diff and grep the final trees for corrected symbols before pushing bottom-up. When a base PR merges, rebuild the remaining stack from that merged commit and repeat the per-PR diff audit.

## Local Visual Recap Surface

Use a self-contained local visual recap as the primary review surface. Read `references/visual-recap.md` in full. It owns the self-contained contract, causal explanation, final understanding quiz, structured-blocks component library, canonical shape/budgets, and validation and serving steps.

## Output Format

- Write the full review to `./tmp/review-<branch-name>.md`.
- Create the user-facing local recap in `./tmp/review-<branch-name>-recap/` unless the user asks for a checked-in artifact. The recap is the primary surface the user reads and must include `index.html` plus `review.md`.
- Start the Markdown file with a one-line note of **which passes ran and which were skipped** (with reason).
- The Markdown file has these top-level sections, in this order. They do not mix:
  - `## Architecture` - the confirmed verdict from Phase 2, one short block.
  - `## Bugs` - Correctness findings. Labels: `**Incorrect:**` (logic produces wrong result), `**Model:**` (data/modeling approach doesn't make sense).
  - `## Testing` - coverage gaps and critiques of the tests in the diff. Labels: `**Test gap:**` (missing coverage, with a proposed test), `**Test smell:**` (an added/changed test that's wrong or weak: imprecise assertion, redundant, asserts implementation detail).
  - `## Performance` - validated wins with benchmark numbers. Label: `**Perf:**`.
  - `## Simplification` - over-engineering to cut. Labels match the pass tags: `**delete:**`, `**stdlib:**`, `**native:**`, `**yagni:**`, `**shrink:**`. End the section with `net: -<N> lines possible`, or `Lean already.` if there were no findings.
  - `## Nits` - non-functional, main-thread style. Labels: `**Unclear:**` (naming/control flow unclear), `**Nit:**` (style).
- Under each Markdown section, group comments by file with a sub-heading: `### <file_path>:<line_number>` and number comments under each file.
- **Every comment must demand a response.** It must either propose a concrete change (old/new code blocks) or ask a specific question the author needs to answer. Do **not** write observational "FYI / this is happening / not a problem but be aware" comments. If there's no ask and no risk worth surfacing, drop it.
- For non-obvious findings, include enough local code context to make the claim readable without a follow-up. Name the relevant function chain or data path, and cite the exact code sites where the accepted input, transformation, and bad outcome happen. Example shape: "`zServerRow` accepts recursive `children` -> `parseRow` preserves recursive children -> `detailGridOptions` renders only one plain child grid." Do this in the review comment itself, not only in private analysis.
- After writing the Markdown and HTML, inspect the generated files for placeholders, broken anchors, and missing sections. If a repo-native checker exists for HTML or Markdown, run it; do not install one.
- Present the served local URL, recap `index.html` path, and folder path in chat, plus a short count by section. Do **not** walk comments one at a time in the terminal unless the user explicitly asks for that mode.
- When the user references a recap item/comment and accepts a concrete change (for example "yeah let's do that" / "ok" on a finding with old/new code blocks), apply the change before moving to another item. Update `./tmp/review-<branch-name>.md`, `review.md`, and `index.html` so the UI tracks the current code.
- **Read hedge phrases in a comment as the floor, not the ceiling.** When implementing a comment (yours or a delegated reviewer's), "at minimum one test", "even just X", "at least Y" name the *smallest acceptable* fix, not the whole fix. If the comment identified a systemic gap ("every `*_normalized` field is exercised at ratio=1 only"), the fix is the systemic one (harden every field), not the one example the hedge named. If the full version is large, surface that to the user ("the full fix touches N sites: all, or a subset?") rather than silently shipping the floor.
- When the user redirects mid-review to make a code change unrelated to the referenced recap item, after applying the redirected change, refresh the saved review file and local recap so they track current code state. Do not silently continue with stale comments.
