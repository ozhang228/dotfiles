# Local Visual Recap Authoring

Use this reference when authoring the local visual recap artifact for code
review.

## Self-Contained Contract

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
library in `references/structured-blocks.md`. Read that file in full before
authoring `index.html`; do not hand-roll a diff view, file tree, or
data-model card from memory. It defines the token CSS, the split-diff
component (real line numbers, before/after, annotation markers), annotated
code, key-change tabs, file tree, data-model / API-endpoint cards, before/after
columns, and two-panel diagrams — all plain HTML/CSS with a little vanilla JS,
no build step. Copy the CSS into `index.html`'s own `<style>` tag once.

## Diff → Block Mapping

Map each kind of change to the block that carries it, derived **mechanically**
from the actual diff — never invented, rounded, or approximated. Full block
definitions and the choice table are in `references/structured-blocks.md`;
the short version:

- **Schema/migration change** → `data-model` card, field-level `change` flags
  (`added`/`modified`/`removed`/`renamed`), `was →` for anything that changed
  shape. This is the headline; reach for a literal SQL diff only when the
  exact statement still matters.
- **API/action/route change** → `api-endpoint` card with the method, path,
  and real request/response JSON. Flag changed params the same way a
  data-model field is flagged.
- **Any meaningful code hunk** → `diff` block, split (side-by-side), with a
  one-line `summary` and a few `note-marker` annotations on the load-bearing
  lines. Never leave a diff unlabeled.
- **Brand-new file / substantial new block** → `annotated-code` instead of a
  one-sided diff.
- **Files added/removed/renamed** → `file-tree` with `change` flags.
- **Several key files needing full diffs** → group under `tabs` (3-8 tabs,
  horizontal only, one file per tab) so each split diff gets full width.
- **Structured before/after** (schema/contract shape) → `columns`, not two
  stacked cards.
- **Architecture or data-flow shift** → two-panel/swimlane `diagram`. Never
  reduce a structural change to one left-to-right arrow chain.
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
part. Three parts, top to bottom:

1. **Understanding the PR.** Prose, grounded in the tests (Phase 1 step 6:
   read the tests first). Summarize succinctly what the PR does and why —
   the behavior a reader needs before looking at a single line of the diff.
   This is not a findings list yet; it's the same understanding the tests
   gave you, handed to the reader.
2. **Modeling.** The deeper why: the confirmed architecture verdict from
   Phase 2, plus `data-model` / `api-endpoint` blocks wherever the PR touches
   schema or contracts, explaining the design choices and whether they hold
   up — not just what the code does, why it's shaped this way.
3. **The review.** `file-tree` of the changed files, then `## Key changes` —
   one horizontal `tabs` block of `diff` / `annotated-code` with annotations
   calling out what's important, then the grouped findings (Bugs / Testing /
   Performance / Simplification / Nits) with stable ids, per the Output
   Format in `SKILL.md`.

Budgets that keep the recap reviewable:

- 3-8 key-change tabs. Fewer than 3 on a large change under-serves the
  reviewer; more than 8 stops being a summary — trim to the truly key files
  and let the file tree carry the rest.
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
used in `index.html`.

## Validation

Before handoff:

- Confirm `index.html` and `review.md` exist.
- Read the generated files enough to catch placeholders, stale claims,
  contradictions, broken anchors, or missing expected sections.
- Open `index.html` mentally against `references/structured-blocks.md`'s
  component definitions — every class referenced must be defined in the
  page's own `<style>` tag (no partial copy-paste of the token CSS).
- Run repo-native checks only when they already exist locally. Do not install
  validators.
- Serve the recap directory with an already-available local static server
  (e.g. `python3 -m http.server`) and report the browser URL. If serving
  fails, report the failure and still provide the direct file path.
- Report the folder path and direct `index.html` path.
