# Local Visual Plan Authoring

Use this reference when authoring the local visual plan artifact for the brainstorm skill.

## Self-Contained Contract

- Use the canonical dark neutral/amber token system from `references/structured-blocks.md`. 
- Do not install packages, execute remote packages, fetch a remote schema, publish plan content, or depend on any external server.
- `tmp/plan.html` is the primary review UI; `tmp/plan.md` is the source-of-truth text fallback.
- Feedback comes through chat or file edits. Update the local files directly.

## Structured blocks

Build `plan.html` from the component library in `references/structured-blocks.md`
(shared with `code-review` - that file is the single canonical copy). Read it
in full before authoring `plan.html`; never hand-roll a block from memory.

Brainstorm reaches for: `summary-card`, `callout`, `options-compare`,
`assumption-list`, `api-endpoint`, `columns`, and `boundary-matrix`. Copy only
the CSS for the blocks actually used into `plan.html`'s own `<style>` tag. End
every plan with the shared `quiz` block.
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
- **Final understanding check** → `quiz`, with 3–5 scored questions and answer
  rationales.
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

## Plan Body Shape

A visual plan reads as a narrative someone can act on, not a form. Open with
a descriptive title, not a decorative category tag, followed by the ask.
Every explanation must answer three distinct questions: **Intent:** what
outcome or constraint motivates the work? **Why this design:** why does the
recommended mechanism fit better than the closest alternative? **What
happens:** how does a representative input move through success and relevant
failure paths to an observable result? Do not collapse these into a vague
summary of benefits.

1. **Title and the Ask** — a descriptive title, then reiterate what's being
   asked in a short `callout` or 2-4 item list. The first viewport must make
   the requested outcome easy to identify before the summary cards.
2. **One-minute design summary.** State the current behavior, proposed
   behavior, scope, and essential design claim. Make the essential claim a
   causal sentence: because the design does X, the user or system can now
   observe Y. Do not turn this into a generic benefits list.
3. **Background and failure mode.** Introduce only the concepts and system
   boundaries needed to understand the proposal, then walk through the
   smallest concrete scenario that fails today. Skip this beat when the
   current behavior is already obvious.
4. **Core intuition and end-to-end flow.** Explain the recommendation in one
   memorable idea, then trace a representative input through each meaningful
   stage to its observable result. Name the durable unit of work, success,
   failure/retry, and ordering where they matter. Organize the flow around
   behavior and ownership, not a list of files.
5. **What needs to be done, concretely, and how each behavior will be
   verified.** Pair concrete requirements with prose or a `summary-card`
   grid. Mark each as a new test, invariant, or manual check so the plan
   keeps design intent without promising redundant tests (see
   `references/testing.md`).
6. **Assumptions.** Use `assumption-list` for any load-bearing assumption the
   design depends on, flagged `verified` / `unverified` / `todo`.
7. **Approach and design anatomy.** Start with the mechanism, then map its
   stages to owned code areas. When a small central behavior requires broad
   supporting changes, explain why each boundary must participate instead of
   presenting the breadth as a changed-files inventory. When the design
   changes state, concurrency, or partial failure, show the smallest concrete
   before/after scenario that makes the difference observable. Use
   `api-endpoint` for contract changes, `options-compare` when there were
   real alternatives worth showing, `columns` for a before/after state
   comparison.
8. **Failure boundaries, when applicable.** `boundary-matrix` when failures
   are handled at more than one scope. A row must justify why identity,
   ordering, or transaction state remains trustworthy enough for that
   recovery.
9. **Whatever else the plan needs.** Performance boundaries, risks, a single
   bottom `## Open Questions` section for anything genuinely unresolved.
   Don't force a section that has nothing to say for this particular plan.
10. **Check your understanding.** Always finish with a `quiz`. Ask 3–5
    questions covering the intent, recommended mechanism, why it beats the
    closest alternative, the load-bearing invariant or failure boundary, and
    the observable success behavior. Omit a category only when it genuinely
    does not apply; do not replace it with trivia.

The numbered beats define explanatory order, not mandatory visible headings.
Combine adjacent beats when the result reads more naturally, and omit
background, anatomy, or failure-boundary material that has nothing useful to
say. Keep the causal chain and the final quiz.

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
Include every quiz question, its choices, the correct answer, and targeted
feedback for every choice so the visual quiz can be regenerated without
reverse-engineering the HTML.
The implementation plan in `tmp/PLAN.md` does not need to repeat the quiz.

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
- Confirm the final section is a 3–5 question quiz, every question has exactly
  one correct answer, selecting an answer immediately shows that question's
  choice-specific feedback, changing the answer clears the previous state, and
  Reset works without errors.
- Confirm the questions test the mechanism and consequences rather than file
  names, line numbers, hashes, or other recall trivia.
- Run repo-native checks only when they already exist locally. Do not install
  validators.
- Serve `tmp/` with an already-available local static server
  (e.g. `python3 -m http.server`), bound to `0.0.0.0`, and report the
  reachable URL. If serving fails, report the failure and still provide the
  direct file path.
- Report the `tmp/plan.html` path.
