---
name: pr-context
description: Draft the `## Context` section of a PR description the way strong authors in Oscar's codebase write them. Use when drafting a new PR body, editing an existing PR description, writing a commit-message context block, or when the user asks for "the PR context" / "PR body" / "context for this change". Enforces the rule "title says what, Context says why", length discipline based on motivation obviousness, and concrete-evidence preference.
---

# PR Context

Distilled from ~50 merged PRs each by pnickols, alchen, ajyang in desk-tools.

## The core rule

**Lead with the problem. The title says what the PR does. Context says why it needed to happen.**

If you find yourself writing "This PR does X", delete it. The diff already does X.

## Length is dictated by how obvious the motivation is

| Situation                 | Length                                 | Real examples                                                                                                                                                   |
| ------------------------- | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Title is self-explanatory | **Empty or 1 line**                    | "Missed this prior before e2e testing" · "3 additional seats + valid until 2027" · "follow-up #2465" · "Used in #2546" · "This will be pointed at QA positions" |
| Clear one-line motivation | **1 sentence**                         | "Avoids a footgun where we're using a different GCC version in CI." · "Till now, gamma/delta weighting for APO decomp rows is wrong, and defaults to 1"         |
| Non-obvious root cause    | **Paragraph(s) + evidence**            | see Root cause examples below                                                                                                                                   |
| Design trade-off          | **Paragraph enumerating alternatives** | see Trade-off examples below                                                                                                                                    |

Do NOT pad short-motivation PRs into long paragraphs. Empty is valid when the title carries the load.

## Concrete evidence beats prose

Paste it when you have it. From real PRs:

- **Related PR link**: "See https://git.drwholdings.com/…/pull/2684" (pnickols)
- **Jira inline**: "Ticket is open to clean this up https://jira.drwholdings.com/browse/JFICC-22354 but don't want this to be blocking now." (pnickols)
- **Slack link**: "https://drw.slack.com/archives/C04DWQB9NR3/p177…" (alchen) · "https://drw.slack.com/archives/C092TTS4H27/p177…" (ajyang)
- **Screenshot / image**: ajyang drops screenshots constantly — a broken log, a config diff, the before/after state. No caption needed.
- **Concrete metric**: "30–50s staleness" · "400ms of inactivity" · "2.9s → 0.02s"
- **Wiki / doc link**: "Long term … we should converge to [this guideline](https://wiki.drwholdings.com/…)" (alchen)
- **Stack trace / log snippet** in a fenced code block

Prose like "there was a performance issue" is much weaker than a `2.9s → 0.02s` screenshot.

## Root cause examples (real)

**pnickols** — connective narrative, explains mechanism, names the edge case:

> "Right now the logic for delta (and gamma) weighting is wrong. This is because we don't map products correctly. There is some subtlety here. This PR fixes all non-apo-decomp rows. (They are subtle too because there you need to map the decomposed row not the underlying)"

**alchen** — multi-step mechanistic with bolded key contributor:

> "Risk viewer's 'Last market data update' staleness on the crude desk was 30–50s. The biggest single contributor: `AttachFutureYtes` and `AttachOneDayLengths` query Event Horizon for YTE/day-length data on **every mapper cycle**, because the crude configs are missing the `caching` block that centerbook configs already use."

**ajyang** — short + screenshot, lets the image carry the weight:

> "These are misleading / resulted in a misconfiguration for centerbook risk publisher in QA since this erroneously hardcoded (EOD, 1h) as the default intervals rather than (EOD, 24h). I think best for configs to be explicit generally
> [image]"

## Trade-off examples (real)

**pnickols** — enumerates options, names what's lost:

> "Unfortunately this destroys info since then a future under BCX2026 is indistinguishable whether it is on BCS or BC. So we add that part to the label too, which obviates the need for #2685 (sorry Peter) and does mean centerbook view will change (but only minorly)"

**alchen** — short-term vs long-term framing:

> "NOTE: this still puts the query in the hot path. End state should be that we put it in a background thread so that mapper itself can be within a few millis, but not an immediate concern right now (as we need to redo the apo stack anyways soon enough)"

**pnickols** — noting what's NOT addressed:

> "This is not something we need noise around always, since it's expected for some products and is what edo-risk does. Missing price ratio however is not (edo-risk also defaults this but I don't think that's principled and we should make noise for that)"

## Patterns that work

### Bug-fix template

1. Observed symptom (screenshot / URL / error log).
2. Root cause (one paragraph).
3. Fix (one line — optional if obvious from title).

### Performance template

1. Observed metric + what's slow.
2. Root cause with bolded key contributor.
3. The change (brief).
4. After-numbers or screenshot.

### Refactor template

1. What's being replaced by what.
2. Why the old thing was awkward.
3. **"Why we can't eliminate X entirely"** if there's a visible structural limit.

### Chain-of-PRs

`follow up to #2389` / `Used in #2546` / `N.B. Relies on #2595`. Short is fine because the linked PR carries the context.

### Uncertainty callouts (net-positive)

"still a bit undecided on the structure of the directory - need to think more" (alchen).
"This should maybe go in bento, but not sure yet."
Flagging a design choice as unstable invites review on that specific thing.

### `N.B.` footnotes

pnickols uses `N.B.` for caveats that don't change the fix but a reviewer should know about.

### Short-term / long-term split

alchen pattern: state what this PR doesn't do yet, and why that's fine:

> "Short term / mid-long term, if they see value in formally productionizing / canonicalizing the project we can revisit."

## What NOT to include

- **Restatement of the title.** "This PR adds X" when the title is "/feature add X" is filler.
- **File-by-file walkthrough.** The diff does this.
- **Implementation description** (class names, modules touched, function signatures). The diff does this too.
- **Scope hedges** like "this is strictly additive". Only include if a reviewer would otherwise worry.
- **Verification/screenshots.** Those go under `## Verification Steps`, not Context.
- **Jira ticket description paraphrased.** Link it. Don't copy.

## Author voice (match the prevailing style)

| Author   | Voice                                       | Signals                                                                                                                  |
| -------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| pnickols | Conversational, connective, reasoning-first | "There is some subtlety here", "Unfortunately this destroys info", "sorry Peter", "shenanigans", explicit PR/Jira chains |
| alchen   | Systems thinker, temporal horizons, metrics | "30–50s", "mid-long term", "megachonker PR", Slack links, wiki links                                                     |
| ajyang   | Terse + visual, configuration-focused       | Heavy screenshots, "footgun", port numbers, direct "X wasn't started" root cause                                         |

## Red flags when self-reviewing

- Multiple paragraphs for a trivial change. Cut ruthlessly.
- Headers inside `## Context` (e.g. `### Problem`, `### Solution`). Pick one frame.
- "This PR" used more than once. You're restating.
- Explaining class / module structure. That's code, not context.
- Every sentence starts with "This" or "We". You're narrating what you did, not why it was needed.

## Process

1. `gh pr list --state merged --limit 10 --author <author>` and skim 3 recent Contexts before writing. Match the prevailing brevity and evidence style.
2. Draft Context first. Forces you to justify the change in your own head.
3. Cut ruthlessly: if a sentence explains HOW rather than WHY, delete it.
4. Paste concrete evidence (URL, log, screenshot, benchmark, Slack link) wherever available.
