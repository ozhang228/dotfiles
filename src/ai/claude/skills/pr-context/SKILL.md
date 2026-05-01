---
name: pr-context
description: Draft the `## Context` section of a PR description the way strong authors in Oscar's codebase write them. Use when drafting a new PR body, editing an existing PR description, writing a commit-message context block, or when the user asks for "the PR context" / "PR body" / "context for this change". Enforces the rule "title says what, Context says why", length discipline based on motivation obviousness, and concrete-evidence preference.
---

# PR Context

Distilled from ~50 merged PRs by strong authors in desk-tools (pnickols, alchen, ajyang).

## The core rule

**Lead with the problem. The title says what the PR does. Context says why it needed to happen.**

If you find yourself writing "This PR does X", delete it. The diff already does X.

## Length is dictated by how obvious the motivation is

| Situation | Length | Examples |
|---|---|---|
| Title is self-explanatory | **Empty or 1 line** | "routine upgrade", "as title", "follow up to #2389", "Used in #2546" |
| Clear one-line motivation | **1 sentence** | "Avoids a footgun where we're using a different GCC version in CI." |
| Non-obvious root cause | **Paragraph(s) + evidence** | React-ag-grid OOM (detailed multi-step mechanism); refdata proto/dataclass field-name divergence (table) |
| Design trade-off rejected | **Paragraph enumerating alternatives** | APO Greek association: "We could show it as an option… This is not clean because… We could show it as a future… This is wrong because… We choose a third category." |

Do NOT pad short-motivation PRs into long paragraphs. Empty is valid when the title carries the load.

## Concrete evidence beats prose

When you have it, paste it. Strong authors do this constantly:

- **Observed error** (URL + entity IDs + error messages, verbatim)
- **Benchmark table** before/after with speedup column
- **Screenshot** of the bug or of the fix in action
- **Slack thread link** ("Crude asked if they could see all users presets")
- **Jira ticket link** inline (not just in the separate `Related Tickets` section when the ticket is itself the motivation)
- **Stack trace / log snippet** in a fenced code block
- **Table** for state comparison (e.g. "child product → parent product mapping")

Prose like "there was a performance issue" is much weaker than a `2.9s → 0.02s` screenshot.

## Patterns that work

### Bug-fix template
1. Observed symptom (screenshot / URL / error log).
2. Root cause (one paragraph).
3. Fix (one line).

### Performance template
1. "I benchmarked X and found Y is the bottleneck" + profile screenshot.
2. Root cause (often one paragraph with a documentation ref).
3. The change (bullet list of what was touched).
4. After-numbers screenshot.

### Refactor template
1. What's being replaced by what.
2. Why the old thing was awkward.
3. **"Why we can't eliminate X entirely"** section if the refactor has a visible structural limit. Acknowledging the limit makes the choice legible.

### Chain-of-PRs
`follow up to #2389` / `Used in #2546` / `N.B. Relies on #2595`. Short is fine because the linked PR carries the context.

### Uncertainty callouts
"still a bit undecided on the structure of the directory - need to think more" (alchen).
"This should maybe go in bento, but not sure yet".
These are net-positive. Flagging a design choice as unstable invites review on that specific thing rather than pretending it's final.

### `N.B.` footnotes
pnickols uses `N.B.` to tack on a caveat that would otherwise break the main explanation's flow. Good for: caveats that don't change the fix but a reviewer should know about.

## What NOT to include

- **Restatement of the title.** "This PR adds X" when the title is "/feature add X" is filler.
- **File-by-file walkthrough.** The diff does this.
- **Implementation description** (class names, modules touched, function signatures). The diff does this too.
- **Scope hedges** like "this is strictly additive" or "all existing configs keep parsing". Only include if a reviewer would otherwise worry about it. Usually they wouldn't.
- **Verification/screenshots.** Those go under `## Verification Steps`, not Context.
- **Jira ticket description paraphrased.** Link it. Don't copy.

## Red flags when self-reviewing your own draft

- Multiple paragraphs for a trivial change. Cut ruthlessly.
- Headers inside `## Context` (e.g. `### Problem`, `### Solution`). Pick one frame and delete the other.
- "This PR" used more than once. You're restating.
- Explaining ADT / class / module structure. That's code, not context.
- Every sentence starts with "This" or "We". You're narrating what you did, not why it was needed.

## Process

1. Before opening the PR, `gh pr list --state merged --limit 10 --author <strong-author>` and skim 3 recent Contexts. Match the prevailing brevity and evidence style.
2. Draft Context first. Forces you to justify the change in your own head.
3. Cut ruthlessly: if a sentence explains HOW rather than WHY, delete it.
4. Paste concrete evidence (URL, log, screenshot, benchmark, slack link) wherever available.
