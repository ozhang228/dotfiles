# Local Visual Recap Authoring

Use this reference when authoring the local visual recap artifact for code
review.

## Self-Contained Contract

- Use the canonical light high-contrast token system from
  `references/structured-blocks.md`. Do not add dark-mode overrides or a
  separate decorative palette.

- Keep recap content local. Read diff, stat, and source context from local
  files and shell commands only.
- Do not install packages, execute remote packages, fetch a remote schema,
  publish recap content, or depend on any external server.
- Use `./tmp/review-<branch-name>-recap/` for scratch artifacts. Use
  `plans/<slug>/` only when the user explicitly wants the artifact checked in.
- The recap directory contains `index.html` as the primary review UI and
  `review.md` as the source-of-truth text fallback. Optional assets must live
  inside the same folder.
- The HTML must be self-contained: inline CSS, no external CDN, no remote
  fonts, no remote scripts, and no runtime dependency outside a browser
  opening the file.
- Feedback comes through chat or file edits. When the user references a recap
  item, update code and local review files directly.

## Structured blocks, not text-on-a-page

`index.html` is not prose poured into HTML — it's built from the component
library in `references/structured-blocks.md` (shared with `brainstorm` -
that file is the single canonical copy). Read that file in full before
authoring `index.html`; do not hand-roll a diff view or API-endpoint card
from memory. It defines the token CSS, the split-diff component (real line
numbers, before/after, annotation markers), annotated code, API-endpoint
cards, before/after columns, two-panel diagrams, and the final scored `quiz`,
all plain HTML/CSS with a little vanilla JS and no build step. Copy the CSS
into `index.html`'s own `<style>` tag once.

## Diff → Block Mapping

Map each kind of change to the block that carries it, derived **mechanically**
from the actual diff — never invented, rounded, or approximated. Full block
definitions and the choice table are in `references/structured-blocks.md`;
the short version:

- **Schema/migration change** → `diff` block on the migration file itself;
  there's no dedicated schema-card block.
- **API/action/route change** → `api-endpoint` card with the method, path,
  and real request/response JSON. Flag changed params with a `badge` +
  `.was` + arrow, same pattern as other change flags in this library.
- **Any meaningful code hunk** → `diff` block, split (side-by-side), with a
  one-line `summary` and a few `note-marker` annotations on the load-bearing
  lines. Never leave a diff unlabeled.
- **Brand-new file / substantial new block** → `annotated-code` instead of a
  one-sided diff.
- **Structured before/after** (schema/contract shape) → `columns`, not two
  stacked cards.
- **Architecture or data-flow shift** → two-panel/swimlane `diagram`. Never
  reduce a structural change to one left-to-right arrow chain.
- **Different failure handling scopes** → `boundary-matrix`, with one row per
  failure naming the handling scope and why partial recovery is safe.
- **Final understanding check** → `quiz`, with 3–5 scored questions and answer
  rationales.
- **Rendered UI/interaction change** → describe the before/after in prose, or
  use `columns` for a structured before/after when the states are simple
  enough to summarize as fields, not a `diagram`.

## Folder Shape

```text
<plan-dir>/
  index.html
  review.md
  assets/       # optional local images or generated files
```

## Canonical Shape And Budgets

A recap reads like a review someone walks through, not a section checklist.
No decorative title or category-tag header — open straight into the first
part. Keep three questions distinct throughout the explanation: **Intent:**
what outcome or constraint motivated the PR? **Why this implementation:** why
does this design fit better than the closest alternative? **What happens:**
how does a representative input travel through the success and relevant
failure paths to an observable result? Four parts, top to bottom:

1. **Understanding the PR.** This is the core of the recap, not a short preface.
   Build the reader's intuition in causal order:
   - Open with a one-minute summary of before, after, scope, and the essential
     behavior. The essential behavior must connect mechanism to outcome.
   - Introduce only the background concepts and system boundaries needed to
     understand the diff.
   - Walk through the smallest concrete failure scenario under the old
     behavior.
   - State the core intuition in one memorable idea, then trace a representative
     input through the end-to-end flow to its observable result.
   - Walk through the implementation by behavioral stage and ownership. When a
     small central algorithm produces a broad diff, explain which typed,
     process, persistence, or error-reporting boundaries force the supporting
     changes.
   - Explain why the strongest verification would fail under the broken
     implementation, not just which command passed.

   Omit beats that have nothing useful to say, and combine adjacent beats when
   that reads better. Name the durable unit of work, success, failure/retry,
   and ordering when those concepts matter. Embed a focused diff, model, API,
   or diagram only where it advances that explanation; organize around
   concepts and behavior, not files.
2. **Modeling.** The deeper why: the confirmed architecture verdict from
   Phase 2, plus `api-endpoint` blocks (and a `diff` on any migration file)
   wherever the PR touches schema or contracts, explaining the design
   choices and whether they hold
   up. Add a `boundary-matrix` when failures are handled at different scopes;
   partial recovery is valid only while identity, ordering, or transaction
   state remains trustworthy.
3. **The review.** Group findings as Bugs / Testing / Performance /
   Simplification / Nits with stable ids, per the Output Format in `SKILL.md`.
   Include the minimum local code context each finding needs. Do not add
   separate Changed Files or Key Changes sections; a path list does not explain
   the change, and detached hunks lack the intuition needed to interpret them.
4. **Check your understanding.** Always finish with a `quiz`. Ask 3–5
   questions covering the PR's intent, its core mechanism, an important
   modeling or design choice, what actually happens, and the critical review
   risk or strongest test evidence. When broad supporting changes are
   important to the explanation, include why they are necessary. Do not test
   diff trivia.

For a recap with more than five substantial sections, add a compact anchor
navigation strip after the opening thesis and include the Quiz anchor. Skip
navigation when the whole page already fits a short linear read.

When a non-obvious test carries an important claim, explain its causal oracle:
the broken implementation that would make it fail, deadlock, or time out. A
test name and assertion summary alone do not explain why the evidence is strong.

Budgets that keep the recap reviewable:

- Keep each diff/annotated-code excerpt focused — prefer under ~150 lines per
  tab; summarize or link the rest of a long file instead of dumping it.
- Number markers only on lines with something non-obvious to say — a few
  high-signal notes per file, not one per line.

Skip a visual recap entirely for a genuinely tiny diff that reviews faster as
plain text (see `SKILL.md` for the review-comment findings, which still apply
regardless of recap size).

## Grounding And Redaction

Structured blocks are only useful if derived from the actual changed lines.
Use real paths, fields, methods, payload shapes, and before/after text. Mark
anything inferred (not extracted) as inferred in prose. Redact secrets or
credential-looking values before copying snippets, diffs, examples, or prose
into the recap — obviously fake placeholders only (`sk-•••`), never the real
value.

## Markdown Fallback

`review.md` carries the same source content in plain Markdown for the agent
and for easy regeneration — the structured findings (Bugs/Testing/etc.) plus
a plain-text rendering of the key diffs. It should keep the same stable ids
used in `index.html`. Include every quiz question, its choices, the correct
answer, and targeted feedback for every choice.

## Validation

Before handoff:

- Confirm `index.html` and `review.md` exist.
- Read the generated files enough to catch placeholders, stale claims,
  contradictions, broken anchors, or missing expected sections.
- Open `index.html` mentally against `references/structured-blocks.md`'s
  component definitions — every class referenced must be defined in the
  page's own `<style>` tag (no partial copy-paste of the token CSS).
- Confirm the final section is a 3–5 question quiz, every question has exactly
  one correct answer, selecting an answer immediately shows that question's
  choice-specific feedback, changing the answer clears the previous state, and
  Reset works without errors.
- Confirm the questions test the mechanism and consequences rather than file
  names, line numbers, hashes, diff counts, or other recall trivia.
- Run repo-native checks only when they already exist locally. Do not install
  validators.
- Serve the recap directory with an already-available local static server
  (e.g. `python3 -m http.server`) and report the browser URL. If serving
  fails, report the failure and still provide the direct file path.
- Report the folder path and direct `index.html` path.
