# Local Visual Plan Authoring

Use this reference when authoring the local visual plan artifact for the brainstorm skill.

## Self-Contained Contract

- Use the canonical dark neutral/amber token system from
  `references/structured-blocks.md`. Do not add light-mode overrides or a
  separate decorative palette.

- Keep plan content local. Read project context from local files and shell
  commands only.
- Do not install packages, execute remote packages, fetch a remote schema,
  publish plan content, or depend on any external server.
- Use `./tmp/visual-plan-<slug>/` for scratch artifacts. Use `plans/<slug>/`
  only when the user explicitly wants the artifact checked in.
- The plan directory contains `plan.html` as the primary review UI and
  `plan.md` as the source-of-truth text fallback. Optional assets must live
  inside the same folder.
- The HTML must be self-contained: inline CSS, no external CDN, no remote
  fonts, no remote scripts, and no runtime dependency outside a browser
  opening the file.
- Feedback comes through chat or file edits. Update the local files directly.

## Structured blocks, not text-on-a-page

`plan.html` is not prose poured into HTML — it's built from the component
library in `references/structured-blocks.md` (shared with `code-review` -
that file is the single canonical copy). Read that file in full before
authoring `plan.html`; do not hand-roll a summary card or comparison table
from memory.

Brainstorm reaches for: `summary-card`, `callout`, `options-compare`,
`assumption-list`, `api-endpoint`, `columns`, and `boundary-matrix`. Copy only
the CSS for the blocks actually used into `plan.html`'s own `<style>` tag.
Skip `section-nav` — a plan is short enough to read linearly; don't add a
navigation strip.

## Idea → Block Mapping

- **First-viewport outcome, hard guards, scope, recommendation** →
  `summary-card` grid.
- **Non-answerable risk, gate, hard constraint, or "no open questions"
  statement** → `callout`.
- **Real alternatives worth showing (3+ options)** → `options-compare`, one
  card marked recommended. Use this instead of a plain Markdown table.
- **Load-bearing assumptions** → `assumption-list`, each row flagged
  `verified` / `unverified` / `todo`. An unverified assumption must render as
  a TODO, not disappear into prose.
- **Proposed API/route contract** → `api-endpoint` card with the method,
  path, and real request/response JSON.
- **Structured before/after or side-by-side decision** → `columns`.
- **Failures handled at different scopes** → `boundary-matrix`, one row per
  failure naming the handling scope and why partial recovery is safe.
- **Before/after architecture or data-flow shift** → describe it in prose,
  scoped to the mechanism (durable unit of work, success, failure/retry,
  ordering); this library has no diagram block for brainstorm. If a genuine
  architecture sketch is needed, use `columns` for the before/after states
  instead of a boxes-and-arrows diagram.
- **A proposed code change to an existing or new file** → describe it in
  prose with the file path and the concrete before/after behavior; this
  library has no diff/code block for brainstorm. If the plan needs to show
  real code line-by-line, that's a signal the work has moved from design into
  implementation — hand it off as a `tmp/PLAN.md` step instead of expanding
  the visual plan.

## Folder Shape

```text
<plan-dir>/
  plan.html
  plan.md
  assets/       # optional local images or generated files
```

## Plan Body Shape

A visual plan reads as a narrative someone can act on, not a form. Open with
a descriptive title, not a decorative category tag, followed by the ask.

1. **Title and the Ask** — a descriptive title, then reiterate what's being
   asked in a short `callout` or 2-4 item list. The first viewport must make
   the requested outcome easy to identify before the summary cards.
2. **What needs to be done, concretely, and how each behavior will be
   verified.** Pair concrete requirements with prose or a `summary-card`
   grid. Mark each as a new test, invariant, or manual check so the plan
   keeps design intent without promising redundant tests (see
   `references/testing.md`).
3. **Assumptions.** `assumption-list` — any load-bearing assumption the
   design depends on, flagged `verified` / `unverified` / `todo`.
4. **Approach.** Start with the mechanism, then the files. Name the durable
   unit of work, success, failure/retry, and ordering. When the design
   changes state, concurrency, or partial failure, show the smallest concrete
   before/after scenario that makes the difference observable. Use
   `api-endpoint` for contract changes, `options-compare` when there were
   real alternatives worth showing, `columns` for a before/after state
   comparison.
5. **Failure boundaries, when applicable.** `boundary-matrix` when failures
   are handled at more than one scope. A row must justify why identity,
   ordering, or transaction state remains trustworthy enough for that
   recovery.
6. **Whatever else the plan needs.** Performance boundaries, risks, a single
   bottom `## Open Questions` section for anything genuinely unresolved.
   Don't force a section that has nothing to say for this particular plan.

A plan stands alone: no "as discussed above," "this revision," or "unlike
the prior version" — fold decisions into normal prose, not changelog
language. When the ask is broader than one motivating example, separate the
reusable core from the specific example/adapter so a reader doesn't mistake
one for the other. No marketing chrome — no hero headings, gradients, or
value-prop cards; this is a technical document.

## Grounding And Redaction

Structured blocks are only useful if derived from real project context —
real file paths, endpoints, and constraints. Mark anything inferred (not
verified) as inferred in prose. Redact secrets or credential-looking values
before copying examples into the plan.

## Markdown Fallback

`plan.md` carries the same source content in plain Markdown for the agent and
for easy regeneration. It should keep the same stable ids used in `plan.html`.

## Validation

Before handoff:

- Confirm `plan.html` and `plan.md` exist.
- Read the generated files enough to catch placeholders, stale claims,
  contradictions, broken anchors, or missing expected sections.
- Open `plan.html` mentally against `references/structured-blocks.md`'s
  component definitions — every class referenced must be defined in the
  page's own `<style>` tag (no partial copy-paste of the token CSS).
- Check that the first viewport is componentized and scannable. If the page
  opens as a long text document, rewrite it with structured blocks before
  handoff.
- Run repo-native checks only when they already exist locally. Do not install
  validators.
- Serve the plan directory with an already-available local static server
  (e.g. `python3 -m http.server`), bound to `0.0.0.0`, and report the
  reachable URL. If serving fails, report the failure and still provide the
  direct file path.
- Report the folder path and direct `plan.html` path.
