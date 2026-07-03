---
name: code-review
description: Orchestrates a multi-agent code review that explains a PR to the user in reading order, deeply enough to understand it, then fans out to four single-purpose subagents (Correctness, Testing, Performance, Simplification) before merging their findings into a structured report. With no diff to review, the same investigative approach produces a guided file:line reading tour of an existing system or feature instead. Use when reviewing pull requests, conducting code quality audits, identifying refactoring opportunities, checking for security issues, or when the user wants to understand how a system/feature/concept works in the codebase. Invoke for PR reviews, code quality checks, refactoring suggestions, review code, code quality, code walkthroughs, "explain how X works", "walk me through Y".
---

# Code Review

You are the **orchestrator**. At its core this skill explains a PR to the user, in reading order, well enough that they deeply understand it — not just a bug list. You do the only deep investigation pass yourself, gate on whether the PR's direction is even right, then fan the line-level review out to four subagents that each focus on exactly one thing. You merge and validate everything they return. The point of the split is focus: each agent is blind to the others' concerns and can't be distracted from its single job.

**No diff to review?** Same skill, same investigative instinct, pointed at an existing system/feature/concept instead of a PR ("explain how X works", "walk me through the auth flow"). Skip the diff-specific mechanics — merge-base resolution, the architecture gate, subagent fan-out, the Bugs/Testing/Performance/Simplification findings sections — and skip straight to producing the reading order itself: identify prerequisites (invariants, vocabulary, abstractions the code assumes), then write `## Prerequisites` followed by `## Reading Tour` with ordered `file:line` stops, each explaining what to look for and why it comes at this point, with your opinions inline (confusing naming, a better structure, why it's built this way). End by inviting the user to read and come back with questions — push toward a verdict ("does this design make sense to you?", "what would you do differently?"), not just comprehension. Length follows the concept: some systems need 3 stops, some need 12. Give `file:line` anchors rather than pasting large snippets — the user reads the real code.

## Reference Guide

Run the bundled `scripts/pr-languages` first to identify which languages are in the diff, then load the relevant language references below. Invoke it from this skill directory or by its resolved filesystem path so it works from any repo CWD.

| Topic             | Reference                         | When                                  |
| ----------------- | --------------------------------- | ------------------------------------- |
| Python            | `references/python.md`            | Any `.py` files in the diff           |
| TypeScript/TSX    | `references/typescript.md`        | Any `.ts` or `.tsx` files in the diff |
| Feedback Examples | `references/feedback-examples.md` | Writing good feedback                 |
| Local Recaps      | `references/visual-recap.md`      | Authoring self-contained local recaps |
| Structured Blocks | `references/structured-blocks.md` | Diff, data-model, API, file-tree, tabs, diagram components |
| Wireframes        | `references/wireframe.md`         | Recapping rendered UI changes         |
| Canvas            | `references/canvas.md`            | Authoring canvas-like recap sections     |

## Review Workflow

The flow is four phases: **you alone** investigate (1) and gate on architecture (2); then you fan out to four subagents (3) and merge what they return (4). Investigation happens exactly once, in the main thread. Subagents never repeat it — you hand them what they need.

### Phase 1 — Investigation (main thread only)

This is the single deep pass over the PR. Do all of it before spawning anything.

1. **Confirm the repo/branch matches the user's active context.** If you're reviewing a branch in one repo while the user's CWD is a different repo or branch, edits during the walkthrough land in the wrong place. Surface any mismatch before proceeding.
2. **Diff against the merge base, not the moving base branch tip.** Resolve the review base with `git -C <repo> merge-base <base> HEAD` and use that SHA for `git diff`, `git diff --stat`, and changed-file discovery. You may note that the branch is behind `<base>`, but do not stop to ask whether to merge before reviewing unless the user explicitly asked for an up-to-date integration review. Reviewing from the merge base avoids attributing unrelated base-branch commits to the PR while preserving the author's current branch state.
3. Run the bundled `scripts/pr-languages` by resolved filesystem path. It computes which languages are changed vs the merge base and auto-detects the repo's real base branch. Note which language references (`references/python.md`, `references/typescript.md`) apply; you'll tell the subagents which to load. Load them yourself too for the architecture verdict.
4. Do a git diff against the merge-base SHA pr-languages resolved (unless another branch or base SHA is specified).
5. Read full files and related files for context. You are the only actor that reads broadly — record exact `file_path:line` ranges for the changed surface so you can hand them to agents without making them re-discover the diff.
6. **Read the tests first.** Tests encode the expected behavior of the PR. They show what the author thinks the code should do. Flag any expected behavior that looks weird, surprising, or wrong _before_ looking at the implementation. Then check the implementation against this understanding.
7. **Check for other open PRs touching the same surface.** Run `gh pr list` (filtered to the changed files/area) before going deep. An overlapping teammate PR means this work may collide or duplicate — surface it to the prompter rather than reviewing in isolation. The same check applies before *writing* a fix in an actively-owned area: don't build a full change into a problem space someone already has an open PR for.

### Phase 2 — Architecture gate (hard block)

Before any line-level review, decide whether the PR is even going the right way. If the direction is wrong, line-level findings are wasted effort. Write to the chat:

- **"The PR is solving X"** — your one-line understanding of intent.
- **An architecture / modeling verdict.** Is this the right approach? The right data model? Challenge implicit assumptions. Commit to a verdict — "I think the approach is sound" or "I'd push back, because Y" — not just a description of what the code does.

Then **stop and wait for the user to confirm the direction.** Do not spawn subagents, do not write any comments, until they confirm. If they want a different approach, the line-level review may be moot — re-scope first.

### Phase 3 — Fan-out (only after confirmation)

Spawn up to four subagents with the host multi-agent tool, each focused on exactly one thing. In Codex, if no subagent tool is visible, use `tool_search` to discover the multi-agent spawn tool before falling back to a main-thread pass. **You decide which to spawn** — skip an agent with no surface area (a docs/config-only PR skips Performance; a pure refactor with full existing coverage may skip Testing; a one-line bugfix skips Simplification) and record the skip + reason for the report. Run the agents you do spawn in parallel when the host supports it.

Each agent gets a **context packet** so it doesn't re-investigate:

- the "PR is solving X" summary and your confirmed architecture verdict
- the exact file list + `line` ranges to review (the agent reads only what you point it at)
- which language reference to load for those files (`references/python.md` / `references/typescript.md`) — tell it to read that file first
- the return contract below

The four agents:

| Agent           | Sole focus                                            | Tools                    | Must do |
| --------------- | ----------------------------------------------------- | ------------------------ | ------- |
| **Correctness** | Will this run as expected?                            | Read, Grep, Glob         | For each finding, give a **concrete triggering input** + expected-vs-actual behavior. Re-trace the path. If it can't construct a failure case, the bug isn't real — drop it or downgrade to a question. Suspected-but-unverified bugs are the top source of bad feedback. |
| **Testing**     | Do tests document each function's behavior, and are the tests in the diff themselves correct? | Read, Grep, Glob         | Two jobs. **(a) Gaps:** map every changed function → the test(s) that pin its behavior; for each gap, **propose a concrete test as a code block**. **(b) Review the added/changed tests themselves** against our testing contract: assertions must match the exact semantic (`assert x == expected`, not `assert x` / `assert len(x)` / `assert x is not None` when the real contract is a specific value); flag redundant tests (two tests exercising the same path, over-parametrized cases that add no new branch); flag tests asserting implementation detail instead of behavior; no fixtures, mocks, or test classes (see `references/python.md`). It proposes and critiques; it does **not** write files. |
| **Performance** | Easy wins that limit performance                      | Read, Grep, Glob, Bash   | Only report a win it **validated with a small benchmark** — include the command and before/after absolute numbers. An unbenchmarked hunch is dropped or downgraded to a question. Reason through the allocation/call model; "looks cleaner" is not "faster". |
| **Simplification** | What in this diff is over-engineered and can be cut?  | Read, Grep, Glob         | Hunt only complexity to delete, never correctness/security/perf. One finding per line, each tagged: `delete:` (dead code, unused flexibility, speculative feature — replacement is nothing), `stdlib:` (hand-rolled thing the standard library ships — name the function), `native:` (dep or code doing what the platform already does — name the feature), `yagni:` (abstraction with one implementation, config nobody sets, layer with one caller), `shrink:` (same logic, fewer lines — show the shorter form). **Readability is a hard floor:** never propose a `shrink:` that trades clarity for line count; a denser one-liner that's harder to read is not a win, drop it. **Never flag the single smoke test or `assert`-based self-check for deletion** — that's the minimum, not bloat. End its return with `net: -<N> lines possible`. If nothing holds up, it returns `Lean already.` and no findings. |

**Return contract** — each agent returns a flat list of findings, no prose padding. Each finding: `file_path:line`, a one-line claim, a severity, and **either** old/new code blocks **or** a specific question the author must answer. Performance findings additionally carry the benchmark command + before/after numbers. Simplification findings carry the tag + the replacement (or `net: -<N> lines possible` at the end).

### Phase 4 — Merge + validate (main thread)

The agents find; you decide what survives.

- **Validate every finding before accepting it.** Re-trace correctness claims against the code you already read. Confirm proposed tests target genuine gaps. Sanity-check that perf numbers are plausible and the benchmark measured the right thing. Drop or downgrade anything that doesn't hold up — the anti-false-positive bar lives here, in the main thread.
- **Drop functionally-equivalent rewrites.** A subagent will sometimes propose a "tightening" or "cleaner" rewrite that compiles to the same behavior and is no clearer to read — same logic, different spelling. That's not a finding. Before accepting any simplification/nit, ask "does the new version actually change behavior, fix a bug, or materially improve readability?" If it's just an equivalent restatement, cut it. Don't relay it to the user.
- **Dedup across agents.** If two agents flag the same line, write one comment.
- **Add style nits yourself.** Naming, clarity, dead code, conventions. This stays a main-thread job because it needs whole-PR context the single-focus agents don't have.

## Resolving review comments (author side)

When the work is the reverse — you're the author addressing comments on your own PR, not producing a review — three failure modes recur:

- **Verify the comment's premise before agreeing or building.** "Use `strikes_from_sds`", "isn't there an outright type for this?", "X already does it this way" are premises, not facts. Grep for the type, read the helper, check what the sibling actually does — *then* act. A premise that turns out false (the canonical helper computes something different, no outright type exists, the sibling diverges) means the change you were about to make is wrong, and reversing an applied change costs more than the check. This holds for pushback too: verify before you defend. The reviewer being senior doesn't make the premise true.
- **Lead placement decisions with ownership, not the import graph.** When a comment is "this doesn't belong here," decide where a thing lives by *what conceptually owns it* (a port belongs with its consumer; an interface with its domain), then use cycle-avoidance to break ties — never let "what imports cleanly" drive the call. Shuffling a file through three locations chasing an import cycle is the symptom of optimizing the graph instead of the ownership.
- **Branch hygiene under concurrent pushes.** When the author (you or Oscar) may be pushing in parallel, re-check `HEAD` vs `origin/<branch>` before every commit and push — a clean-looking `git diff <base>` can be base-ahead churn rather than your change, and a published merge commit must never be amended. Land each fix on the PR/branch that *owns* the file it touches, not whichever branch is checked out.

## Local Visual Recap Surface

Use a self-contained local visual recap as the primary review surface. Read `references/visual-recap.md` in full — it owns the self-contained contract, the structured-blocks component library, the canonical shape/budgets, and the validation and serving steps.

## Output Format

- Write the agent-readable review to `./tmp/review-<branch-name>.md`.
- Create the user-facing local recap in `./tmp/review-<branch-name>-recap/` unless the user asks for a checked-in artifact. The recap is the primary surface the user reads and must include `index.html` plus `review.md`.
- Start the Markdown file with a one-line note of **which agents ran and which were skipped** (with reason).
- The Markdown file has these top-level sections, in this order. They do not mix:
  - `## Architecture` - the confirmed verdict from Phase 2, one short block.
  - `## Bugs` - Correctness findings. Labels: `**Incorrect:**` (logic produces wrong result), `**Model:**` (data/modeling approach doesn't make sense).
  - `## Testing` - coverage gaps and critiques of the tests in the diff. Labels: `**Test gap:**` (missing coverage, with a proposed test), `**Test smell:**` (an added/changed test that's wrong or weak: imprecise assertion, redundant, asserts implementation detail).
  - `## Performance` - validated wins with benchmark numbers. Label: `**Perf:**`.
  - `## Simplification` - over-engineering to cut. Labels match the agent's tags: `**delete:**`, `**stdlib:**`, `**native:**`, `**yagni:**`, `**shrink:**`. End the section with `net: -<N> lines possible`, or `Lean already.` if there were no findings.
  - `## Nits` - non-functional, main-thread style. Labels: `**Unclear:**` (naming/control flow unclear), `**Nit:**` (style).
- Under each Markdown section, group comments by file with a sub-heading: `### <file_path>:<line_number>` and number comments under each file.
- **Every comment must demand a response.** It must either propose a concrete change (old/new code blocks) or ask a specific question the author needs to answer. Do **not** write observational "FYI / this is happening / not a problem but be aware" comments. If there's no ask and no risk worth surfacing, drop it.
- For non-obvious findings, include enough local code context to make the claim readable without a follow-up. Name the relevant function chain or data path, and cite the exact code sites where the accepted input, transformation, and bad outcome happen. Example shape: "`zServerRow` accepts recursive `children` -> `parseRow` preserves recursive children -> `detailGridOptions` renders only one plain child grid." Do this in the review comment itself, not only in private analysis.
- After writing the Markdown and HTML, inspect the generated files for placeholders, broken anchors, and missing sections. If a repo-native checker exists for HTML or Markdown, run it; do not install one.
- Present the served local URL, recap `index.html` path, and folder path in chat, plus a short count by section. Do **not** walk comments one at a time in the terminal unless the user explicitly asks for that mode.
- When the user references a recap item/comment and accepts a concrete change (for example "yeah let's do that" / "ok" on a finding with old/new code blocks), apply the change before moving to another item. Update `./tmp/review-<branch-name>.md`, `review.md`, and `index.html` so the UI tracks the current code.
- **Read hedge phrases in a comment as the floor, not the ceiling.** When implementing a comment (yours or an agent's), "at minimum one test", "even just X", "at least Y" name the *smallest acceptable* fix, not the whole fix. If the comment identified a systemic gap ("every `*_normalized` field is exercised at ratio=1 only"), the fix is the systemic one (harden every field), not the one example the hedge named. If the full version is large, surface that to the user ("the full fix touches N sites: all, or a subset?") rather than silently shipping the floor.
- When the user redirects mid-review to make a code change unrelated to the referenced recap item, after applying the redirected change, refresh the saved review file and local recap so they track current code state. Do not silently continue with stale comments.
