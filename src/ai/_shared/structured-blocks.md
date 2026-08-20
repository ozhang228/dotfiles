# Structured blocks

Canonical, shared component library for turning a diff or a design proposal
into self-contained HTML. `code-review` (recaps) and `brainstorm` (plans) both
read this exact file — it lives here, not inside either skill, and each
skill's own `references/structured-blocks.md` is a symlink to it, so there is
never a second copy to drift out of sync. Read this file in full before
authoring any block; do not improvise diff, endpoint, or summary markup.

**Why plain HTML here.** The output is a static file opened directly in a
browser, with no build step or external dependency. Every block below is
plain HTML + CSS, with vanilla JS only where interactivity earns its keep
(`<details>` disclosure and quiz scoring). No client-side diffing or component
library needed.

**Copy the CSS once per artifact.** Paste the full token + component CSS
below into the artifact's own `<style>` tag. Do not link it externally, do
not partially copy classes — an artifact missing a class it references is a
broken artifact. Fill in real content; never ship the example values.

**Not every skill uses every block.** `code-review` reaches for `diff`,
`annotated-code`, `section-nav`, `api-endpoint`, `columns`, `boundary-matrix`,
`diagram`, and `quiz`. `brainstorm` reaches for `summary-card`, `callout`,
`options-compare`, `assumption-list`, `api-endpoint`, `columns`, and
`boundary-matrix`, plus `quiz`. Each skill's own reference file says which
subset applies there — this file is the full shared vocabulary, not a
per-skill checklist.

## Token system

```css
:root {
  color-scheme: dark;
  --bg: #14171c; --surface: #1b1f27; --surface-2: #20242e; --line: #2b3140;
  --ink: #e4e7ee; --muted: #8b93a7; --accent: #d9a441; --accent-soft: #3a2f18;
  --add: #4bc76b; --add-bg: #12271a; --add-line: #17351f;
  --del: #f0716a; --del-bg: #2c1618; --del-line: #3a1c1f;
  --warn: #e0a52b; --warn-bg: #2e2712;
  --radius: 8px;
  --mono: ui-monospace, "SFMono-Regular", Menlo, Consolas, "Liberation Mono", monospace;
  --sans: -apple-system, "Segoe UI", ui-sans-serif, system-ui, sans-serif;
}
.card { background: var(--surface); border: 1px solid var(--line); border-radius: var(--radius); overflow: hidden; }
.badge {
  font-family: var(--sans); font-size: 10px; font-weight: 700; letter-spacing: 0.02em;
  padding: 1px 6px; border-radius: 4px; text-transform: uppercase; flex: 0 0 auto;
}
.badge.added { color: var(--add); background: var(--add-bg); }
.badge.removed { color: var(--del); background: var(--del-bg); }
.badge.modified { color: var(--accent); background: var(--accent-soft); }
.badge.renamed { color: var(--warn); background: var(--warn-bg); }
```

This dark neutral/amber palette is the canonical visual language for local AI
artifacts. Never hard-code a hex color inside a block's own markup; reference
the token. Reserve green and red for semantic added/success and
removed/failure states.

## Block: section navigation (`section-nav`)

Use only when an artifact has more than five substantial sections. Keep it a
compact strip of real anchor links; short documents read better without it.

```css
.section-nav { display: flex; flex-wrap: wrap; gap: 6px; margin: 12px 0 20px; padding-bottom: 12px; border-bottom: 1px solid var(--line); }
.section-nav a { padding: 5px 9px; border-radius: 5px; background: var(--surface-2); color: var(--muted); text-decoration: none; font-size: 12px; }
.section-nav a:hover { color: var(--ink); }
```

```html
<nav class="section-nav" aria-label="Sections">
  <a href="#understanding">Understanding</a>
  <a href="#modeling">Modeling</a>
  <a href="#review">Review</a>
</nav>
```

Every `href` must resolve to an id in the same document. Do not add links for
minor subsections just to fill the strip.

## Block: split diff (`diff`)

The default for any meaningful code hunk. Side-by-side before/after, real line
numbers, numbered markers anchored to specific lines, notes listed below the
diff so the reviewer reads intent before line noise.

```css
.diff-head { display: flex; align-items: center; gap: 10px; padding: 9px 14px; background: var(--surface-2); border-bottom: 1px solid var(--line); font-family: var(--mono); font-size: 12.5px; }
.diff-head .path { color: var(--ink); }
.diff-head .summary { color: var(--muted); font-family: var(--sans); font-size: 12.5px; margin-left: auto; text-align: right; }
.diff-split { display: grid; grid-template-columns: 1fr 1fr; font-family: var(--mono); font-size: 12.5px; }
.diff-pane + .diff-pane { border-left: 1px solid var(--line); }
.diff-pane { overflow-x: auto; }
.diff-row { display: grid; grid-template-columns: 34px 1fr; width: max-content; min-width: 100%; }
.diff-row .ln { color: var(--muted); text-align: right; padding: 1px 8px; user-select: none; font-variant-numeric: tabular-nums; opacity: 0.7; }
.diff-row .code { padding: 1px 14px 1px 4px; white-space: pre; }
.diff-row.add { background: var(--add-bg); }
.diff-row.add .code { color: var(--add); }
.diff-row.add .ln { background: var(--add-line); }
.diff-row.del { background: var(--del-bg); }
.diff-row.del .code { color: var(--del); }
.diff-row.del .ln { background: var(--del-line); }
.diff-row.blank .code { opacity: 0; }
.note-marker { display: inline-flex; align-items: center; justify-content: center; width: 15px; height: 15px; border-radius: 50%; background: var(--accent); color: var(--surface); font-size: 10px; font-weight: 700; font-family: var(--sans); margin-left: 8px; vertical-align: middle; }
.diff-notes { border-top: 1px solid var(--line); padding: 12px 16px; display: flex; flex-direction: column; gap: 8px; font-size: 13px; }
.diff-notes .note { display: flex; gap: 9px; }
.diff-notes .note .n { flex: 0 0 auto; width: 15px; height: 15px; border-radius: 50%; background: var(--accent); color: var(--surface); font-size: 10px; font-weight: 700; display: flex; align-items: center; justify-content: center; margin-top: 2px; }
.diff-notes .note p { margin: 0; color: var(--ink); }
.diff-notes .note code { font-family: var(--mono); font-size: 12px; background: var(--surface-2); padding: 1px 5px; border-radius: 4px; }
```

```html
<div class="card diff">
  <div class="diff-head">
    <span class="path">auth/session.py</span>
    <span class="summary">one-line summary of what this hunk changes and why</span>
  </div>
  <div class="diff-split">
    <div class="diff-pane">
      <div class="diff-row"><span class="ln">41</span><span class="code">    def refresh(self) -&gt; None:</span></div>
      <div class="diff-row del"><span class="ln">42</span><span class="code">        self.expires_at = now() + SESSION_TTL</span></div>
      <div class="diff-row blank"><span class="ln"></span><span class="code"> </span></div>
    </div>
    <div class="diff-pane">
      <div class="diff-row"><span class="ln">41</span><span class="code">    def refresh(self) -&gt; None:</span></div>
      <div class="diff-row add"><span class="ln">42</span><span class="code">        self.refresh_token_hash = issue_token_hash()<span class="note-marker">1</span></span></div>
      <div class="diff-row add"><span class="ln">43</span><span class="code">        revoke_hash(old_hash)<span class="note-marker">2</span></span></div>
    </div>
  </div>
  <div class="diff-notes">
    <div class="note"><span class="n">1</span><p>Explain what this line does and why it matters, referencing <code>real_identifiers</code>.</p></div>
    <div class="note"><span class="n">2</span><p>A second note, e.g. cross-referencing another block with a link.</p></div>
  </div>
</div>
```

Rules:

- `overflow-x: auto` lives on `.diff-pane`, never on `.code` — one scrollbar
  per pane, not one per row. A `.code` with its own `overflow-x` produces a
  scrollbar-per-line artifact; this was a real bug, verify it doesn't recur.
- Number markers only on lines with something non-obvious to say. Not every
  added line needs one — keep it to a few high-signal notes per file.
- `.diff-row.blank` pads the shorter side so both panes stay line-aligned;
  omit it when line counts already match.
- Real before/after text and real line numbers only, mechanically derived
  from the actual diff — never invented or approximated.

## Block: annotated code (`annotated-code`)

Same visual language as split diff, one column. Use for a brand-new file (no
meaningful "before") instead of an empty left pane.

```css
.anno-code { font-family: var(--mono); font-size: 12.5px; }
```

```html
<div class="card anno-code">
  <div class="diff-head"><span class="path">auth/token_rotation.py</span><span class="summary">new file · 14 lines</span></div>
  <div>
    <div class="diff-row"><span class="ln">1</span><span class="code">def revoke_hash(token_hash: str) -&gt; None:</span></div>
    <div class="diff-row"><span class="ln">2</span><span class="code">    RevokedToken.objects.create(hash=token_hash)<span class="note-marker">1</span></span></div>
  </div>
  <div class="diff-notes">
    <div class="note"><span class="n">1</span><p>Why this line is worth flagging.</p></div>
  </div>
</div>
```

Reuses `.diff-row` / `.diff-notes` / `.note-marker` from the diff block —
define those CSS rules once per artifact, not twice.

## Block: API endpoint (`api-endpoint`)

Method, path, and a real request/response example in a native `<details>`
tree — no JSON library, expand/collapse is free with the browser.

```css
.endpoint { padding: 16px 18px; }
.endpoint-head { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.method-pill { font-family: var(--mono); font-size: 11px; font-weight: 700; padding: 3px 8px; border-radius: 4px; background: var(--accent-soft); color: var(--accent); }
.endpoint-head .path { font-family: var(--mono); font-size: 14px; }
.endpoint-desc { color: var(--muted); font-size: 13px; margin: 0 0 14px; }
.endpoint h4 { font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); margin: 14px 0 6px; }
details.json-explorer summary { cursor: pointer; font-family: var(--mono); font-size: 12.5px; color: var(--ink); background: var(--surface-2); padding: 8px 10px; border-radius: 6px; list-style: none; }
details.json-explorer summary::-webkit-details-marker { display: none; }
details.json-explorer summary::before { content: "▸ "; color: var(--muted); }
details.json-explorer[open] summary::before { content: "▾ "; }
details.json-explorer pre { font-family: var(--mono); font-size: 12.5px; margin: 6px 0 0; padding: 10px 12px; background: var(--surface-2); border-radius: 6px; overflow-x: auto; }
.jk { color: var(--accent); }
.js { color: var(--add); }
.jn { color: #4b8fd9; }
```

```html
<div class="card endpoint">
  <div class="endpoint-head">
    <span class="method-pill">POST</span><span class="path">/auth/refresh</span>
    <span class="badge added" style="margin-left:auto">added</span>
  </div>
  <p class="endpoint-desc">One-sentence description grounded in the diff or spec.</p>
  <h4>Response 200</h4>
  <details class="json-explorer" open>
    <summary>refresh_response</summary>
    <pre>{
  <span class="jk">"access_token"</span>: <span class="js">"eyJhbGciOi..."</span>,
  <span class="jk">"expires_in"</span>: <span class="jn">3600</span>
}</pre>
  </details>
</div>
```

`.jk`/`.js`/`.jn` are manual key/string/number coloring — hand-wrap the real
JSON example's tokens in those spans; there's no JSON.parse step, just
literal text you already have from the diff/spec. Keep each example a single
parseable JSON value; give a websocket frame or an error body its own
labeled `<details>` rather than concatenating shapes into one block.

## Block: before/after columns (`columns`)

Structured side-by-side comparison — for contract shape, not pixels. Nest any
other block (commonly `api-endpoint`) inside each column.

```css
.before-after { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
@media (max-width: 720px) { .before-after { grid-template-columns: 1fr; } }
.ba-col h3 { font-size: 11px; text-transform: uppercase; letter-spacing: 0.05em; color: var(--muted); margin: 0 0 8px; font-weight: 700; }
.ba-col h3.after { color: var(--accent); }
```

```html
<div class="before-after">
  <div class="ba-col"><h3>Before</h3><!-- nested card --></div>
  <div class="ba-col"><h3 class="after">After</h3><!-- nested card --></div>
</div>
```

Use `columns` for a **structured** before/after (schema shape, contract
shape). Use the `diff` block for **code** — it renders literal removed/added
lines, which `columns` cannot.

## Block: failure boundary matrix (`boundary-matrix`)

Use when failures are handled at different scopes. It makes the recovery
contract reviewable: what failed, how much work is discarded or retried, and
why the remaining identity/order/transaction state is still trustworthy.

```css
.boundary-matrix { margin: 16px 0; overflow-x: auto; }
.boundary-matrix table { min-width: 680px; width: 100%; border-collapse: collapse; font-size: 13px; }
.boundary-matrix th { text-align: left; color: var(--muted); font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; }
.boundary-matrix th, .boundary-matrix td { padding: 9px 10px; border-bottom: 1px solid var(--line); vertical-align: top; }
.scope-pill { display: inline-flex; padding: 2px 7px; border: 1px solid var(--accent); border-radius: 4px; background: var(--accent-soft); color: var(--accent); font-size: 12px; white-space: nowrap; }
```

```html
<div class="card boundary-matrix">
  <table>
    <thead><tr><th>Failure</th><th>Handling scope</th><th>Why</th></tr></thead>
    <tbody>
      <tr><td>one known item fails validation</td><td><span class="scope-pill">item</span></td><td>its stable input id lets valid siblings remain committed</td></tr>
      <tr><td>response loses item identity</td><td><span class="scope-pill">whole response</span></td><td>outputs can no longer be mapped safely to inputs</td></tr>
    </tbody>
  </table>
</div>
```

Use real failure modes and observed/designed handling. Do not infer that
partial recovery is safe merely because the implementation attempts it.

## Block: diagram (two-panel / swimlane)

Architecture or data-flow shifts. Plain flex boxes — no diagram library, no
canvas. Use two-dimensional panel/lane layout; don't collapse a structural
change into one left-to-right arrow chain.

```css
.diagram { padding: 22px; display: flex; gap: 22px; align-items: stretch; flex-wrap: wrap; }
.diagram .panel { flex: 1; min-width: 220px; border: 1px dashed var(--line); border-radius: 8px; padding: 14px; }
.diagram .panel h4 { margin: 0 0 12px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
.diagram .node { background: var(--surface-2); border: 1px solid var(--line); border-radius: 6px; padding: 9px 12px; font-family: var(--mono); font-size: 12.5px; margin-bottom: 8px; }
.diagram .node.hot { border-color: var(--accent); background: var(--accent-soft); }
.diagram .connector { display: flex; align-items: center; justify-content: center; color: var(--muted); font-size: 22px; }
```

```html
<div class="card diagram">
  <div class="panel">
    <h4>Before</h4>
    <div class="node">real step name</div>
    <div class="node">real step name</div>
  </div>
  <div class="connector">→</div>
  <div class="panel">
    <h4>After</h4>
    <div class="node">real step name</div>
    <div class="node hot">the changed/new step, marked hot</div>
  </div>
</div>
```

Use `.node.hot` to mark what's new or changed between panels — the reviewer's
eye should land there first. For a swimlane (more than two parallel tracks),
add more `.panel` siblings; flex-wrap keeps it readable instead of forcing a
single unreadable row.

## Block: summary card (`summary-card`)

First-viewport row of cards making the ask scannable before the reader hits
any prose. One card per angle (why, scope, risk, recommendation) — not a
place for a paragraph.

```css
.summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; margin: 16px 0; }
.summary-card { padding: 14px 16px; border-left: 3px solid var(--line); }
.summary-card h3 { margin: 0 0 6px; font-size: 12px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }
.summary-card p { margin: 0; font-size: 13.5px; color: var(--ink); }
.summary-card.good { border-left-color: var(--add); }
.summary-card.warn { border-left-color: var(--warn); }
.summary-card.bad { border-left-color: var(--del); }
```

```html
<div class="summary-grid">
  <div class="card summary-card good">
    <h3>Why</h3>
    <p>One or two sentences on the driving reason.</p>
  </div>
  <div class="card summary-card">
    <h3>Scope</h3>
    <p>What's touched, in one line.</p>
  </div>
  <div class="card summary-card warn">
    <h3>Found while auditing</h3>
    <p>Anything unexpected surfaced during investigation.</p>
  </div>
</div>
```

Tone maps to border color: `good` (green) for a clear win, `warn` (amber) for
something to flag, `bad` (red) for a real cost/risk, no class for neutral.

## Block: callout (`callout`)

A flagged box for a non-negotiable constraint, an unresolved risk, or an
explicit "no open questions" statement. Not a container for ordinary prose —
if it's not worth the reader's extra attention, it doesn't belong in a callout.

```css
.callout { display: flex; gap: 10px; padding: 12px 16px; border-radius: var(--radius); border: 1px solid var(--line); background: var(--surface); }
.callout strong { flex: 0 0 auto; font-size: 12px; text-transform: uppercase; letter-spacing: 0.04em; }
.callout p { margin: 0; font-size: 13.5px; color: var(--ink); }
.callout.good { border-color: var(--add); } .callout.good strong { color: var(--add); }
.callout.warn { border-color: var(--warn); } .callout.warn strong { color: var(--warn); }
.callout.bad { border-color: var(--del); } .callout.bad strong { color: var(--del); }
```

```html
<div class="callout warn">
  <strong>Hard constraint</strong>
  <p>State the non-negotiable rule or unresolved risk in one or two sentences.</p>
</div>
```

## Block: options compare (`options-compare`)

The tradeoff menu for presenting alternatives before committing to one. N
options side by side, each with pros/cons, one marked recommended.

```css
.options-compare { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 14px; margin: 16px 0; }
.option-card { padding: 14px 16px; }
.option-card.recommended { border-color: var(--accent); }
.option-card h3 { margin: 0 0 8px; font-size: 14px; display: flex; align-items: center; gap: 8px; }
.option-card ul { margin: 8px 0 0; padding-left: 18px; font-size: 13px; }
.option-card .pros li { color: var(--add); }
.option-card .cons li { color: var(--del); }
```

```html
<div class="options-compare">
  <div class="card option-card recommended">
    <h3>Option name <span class="badge modified">recommended</span></h3>
    <ul class="pros"><li>concrete pro</li></ul>
    <ul class="cons"><li>concrete con</li></ul>
  </div>
  <div class="card option-card">
    <h3>Alternative name</h3>
    <ul class="pros"><li>concrete pro</li></ul>
    <ul class="cons"><li>concrete con</li></ul>
  </div>
</div>
```

Use this instead of a plain Markdown table once there are 3+ options — a
table doesn't scan as fast as cards for a real decision point.

## Block: assumption list (`assumption-list`)

Load-bearing assumptions a design depends on, status-flagged so an unverified
one can't quietly read as an accepted fact.

```css
.assumption-list { display: flex; flex-direction: column; gap: 8px; margin: 16px 0; }
.assumption-row { display: flex; gap: 10px; align-items: flex-start; padding: 10px 12px; border: 1px solid var(--line); border-radius: 6px; }
.assumption-row p { margin: 0; font-size: 13.5px; }
.badge.status-verified { color: var(--add); background: var(--add-bg); }
.badge.status-unverified { color: var(--warn); background: var(--warn-bg); }
.badge.status-todo { color: var(--del); background: var(--del-bg); }
```

```html
<div class="assumption-list">
  <div class="assumption-row"><span class="badge status-verified">verified</span><p>An assumption already checked against real code/data.</p></div>
  <div class="assumption-row"><span class="badge status-todo">todo</span><p>A load-bearing assumption that still needs a check — never leave this in prose where it reads as accepted.</p></div>
</div>
```

## Block: check your understanding (`quiz`)

The final section of a visual artifact. Use 3–5 multiple-choice questions to
test whether the reader understands the mechanism and its consequences, not
whether they memorized the document. Each question has exactly one correct
answer, plausible distractors, immediate scoring, and a short rationale shown
as soon as the reader selects an answer.

```css
.quiz { padding: 18px; }
.quiz fieldset { margin: 0; padding: 16px 0; border: 0; border-top: 1px solid var(--line); }
.quiz fieldset:first-of-type { padding-top: 0; border-top: 0; }
.quiz legend { padding: 0 0 10px; color: var(--ink); font-size: 14px; font-weight: 700; }
.quiz-options { display: grid; gap: 7px; }
.quiz-option { display: flex; gap: 9px; align-items: flex-start; padding: 9px 11px; border: 1px solid var(--line); border-radius: 6px; color: var(--muted); cursor: pointer; }
.quiz-option:hover { color: var(--ink); background: var(--surface-2); }
.quiz-option input { margin-top: 2px; accent-color: var(--accent); }
.quiz-option.correct { color: var(--add); border-color: var(--add); background: var(--add-bg); }
.quiz-option.incorrect { color: var(--del); border-color: var(--del); background: var(--del-bg); }
.quiz-feedback { margin: 10px 0 0; color: var(--ink); font-size: 13px; }
.quiz-actions { display: flex; align-items: center; flex-wrap: wrap; gap: 9px; padding-top: 14px; border-top: 1px solid var(--line); }
.quiz button { padding: 7px 11px; border: 1px solid var(--accent); border-radius: 5px; background: var(--accent); color: var(--bg); font: 700 12px var(--sans); cursor: pointer; }
.quiz button.quiz-secondary { background: transparent; color: var(--accent); }
.quiz-score { color: var(--ink); font-size: 13px; font-weight: 700; }
```

```html
<form class="card quiz">
  <fieldset data-answer="b">
    <legend>1. What makes the proposed behavior reliable?</legend>
    <div class="quiz-options">
      <label class="quiz-option"><input type="radio" name="q1" value="a">A plausible but incorrect mechanism.</label>
      <p class="quiz-feedback" data-for="a" aria-live="polite" hidden><strong>Not quite.</strong> Explain why this specific mechanism is insufficient, then contrast it with the real mechanism.</p>
      <label class="quiz-option"><input type="radio" name="q1" value="b">The real load-bearing mechanism from the plan or diff.</label>
      <p class="quiz-feedback" data-for="b" aria-live="polite" hidden><strong>Correct.</strong> Explain why this mechanism matters and produces the intended behavior.</p>
      <label class="quiz-option"><input type="radio" name="q1" value="c">A rejected alternative or likely misunderstanding.</label>
      <p class="quiz-feedback" data-for="c" aria-live="polite" hidden><strong>Not quite.</strong> Explain the misconception in this choice and why the actual mechanism avoids it.</p>
    </div>
  </fieldset>
  <fieldset data-answer="a">
    <legend>2. Where does the important failure boundary sit?</legend>
    <div class="quiz-options">
      <label class="quiz-option"><input type="radio" name="q2" value="a">The actual boundary and its observable consequence.</label>
      <p class="quiz-feedback" data-for="a" aria-live="polite" hidden><strong>Correct.</strong> Explain what is contained or rejected at this boundary and why that is safe.</p>
      <label class="quiz-option"><input type="radio" name="q2" value="b">A broader boundary the design deliberately rejected.</label>
      <p class="quiz-feedback" data-for="b" aria-live="polite" hidden><strong>Not quite.</strong> Explain why this boundary discards or retries more work than necessary.</p>
      <label class="quiz-option"><input type="radio" name="q2" value="c">There is no failure boundary.</label>
      <p class="quiz-feedback" data-for="c" aria-live="polite" hidden><strong>Not quite.</strong> Identify the real boundary and the invariant that makes it trustworthy.</p>
    </div>
  </fieldset>
  <fieldset data-answer="c">
    <legend>3. Which observation proves the change works?</legend>
    <div class="quiz-options">
      <label class="quiz-option"><input type="radio" name="q3" value="a">A success-shaped check that does not distinguish old from new behavior.</label>
      <p class="quiz-feedback" data-for="a" aria-live="polite" hidden><strong>Not quite.</strong> Explain why this check can pass under the broken behavior.</p>
      <label class="quiz-option"><input type="radio" name="q3" value="b">An implementation detail unrelated to the user-visible contract.</label>
      <p class="quiz-feedback" data-for="b" aria-live="polite" hidden><strong>Not quite.</strong> Explain why this detail does not prove the intended outcome.</p>
      <label class="quiz-option"><input type="radio" name="q3" value="c">The concrete result that fails before the change and passes after it.</label>
      <p class="quiz-feedback" data-for="c" aria-live="polite" hidden><strong>Correct.</strong> Name the discriminating behavior or evidence, not merely a green command.</p>
    </div>
  </fieldset>
  <div class="quiz-actions">
    <button type="reset" class="quiz-secondary">Reset</button>
    <output class="quiz-score" aria-live="polite"></output>
  </div>
</form>
```

Place this script once before `</body>`. It supports every `.quiz` form in the
artifact without ids or dependencies.

```html
<script>
function updateQuizScore(quiz) {
  const questions = [...quiz.querySelectorAll("fieldset[data-answer]")];
  const answered = questions.filter((question) => question.querySelector("input:checked"));
  const correct = answered.filter(
    (question) => question.querySelector("input:checked").value === question.dataset.answer,
  );
  quiz.querySelector(".quiz-score").textContent =
    `${correct.length} correct · ${answered.length} of ${questions.length} answered`;
}

function answerQuestion(event) {
  const input = event.target.closest("input[type=radio]");
  if (!input) return;

  const question = input.closest("fieldset[data-answer]");
  for (const option of question.querySelectorAll(".quiz-option")) {
    const optionInput = option.querySelector("input");
    option.classList.toggle(
      "correct",
      optionInput.checked && optionInput.value === question.dataset.answer,
    );
    option.classList.toggle(
      "incorrect",
      optionInput.checked && optionInput.value !== question.dataset.answer,
    );
  }
  for (const feedback of question.querySelectorAll(".quiz-feedback")) {
    feedback.hidden = feedback.dataset.for !== input.value;
  }
  updateQuizScore(input.closest(".quiz"));
}

function resetQuiz(event) {
  const quiz = event.currentTarget;
  for (const option of quiz.querySelectorAll(".quiz-option")) {
    option.classList.remove("correct", "incorrect");
  }
  for (const feedback of quiz.querySelectorAll(".quiz-feedback")) {
    feedback.hidden = true;
  }
  quiz.querySelector(".quiz-score").textContent = "";
}

function preventQuizSubmit(event) {
  event.preventDefault();
}

for (const quiz of document.querySelectorAll(".quiz")) {
  quiz.addEventListener("change", answerQuestion);
  quiz.addEventListener("reset", resetQuiz);
  quiz.addEventListener("submit", preventQuizSubmit);
}
</script>
```

Question quality rules:

- Test core intuition, mechanism, tradeoffs, boundaries, and evidence. Never
  test file names, line numbers, commit hashes, diff counts, or other trivia.
- Write distractors from the old behavior, a rejected alternative, or a likely
  misunderstanding. Obviously absurd answers do not test understanding.
- Keep exactly one defensible correct answer. If two options could be right
  under different assumptions, fix the question or state the assumption.
- Write targeted feedback for every choice. A correct choice explains why it
  is right. Each distractor explains why that specific choice is wrong and
  contrasts it with the correct mechanism or outcome. Show only the selected
  choice's feedback, and replace it immediately when the selection changes.
- Use 3 questions for a narrow artifact and up to 5 only when each additional
  question tests a distinct, load-bearing concept.

## Grounding rule

Every block in this file is **true by construction** only if built
mechanically from the real diff, real code, or a genuinely checked fact —
real paths, real fields, real method/path, real before/after text, real
verification status. Never invent, round, or approximate a value inside a
structured block. Prose is the only place free-form judgment, narrative, and
risk assessment belong. A confidently wrong structured block is worse than no
block: a reader who trusts it may skip the exact thing it got wrong.

## Choosing a block

| Kind of content | Block |
| --- | --- |
| Any meaningful code hunk | `diff` (split), one-line `summary`, a few `note-marker` annotations on load-bearing lines |
| Brand-new file / substantial new block | `annotated-code` instead of a one-sided diff |
| API / action / route change or proposal | `api-endpoint` with request/response examples |
| Structured before/after (schema/contract shape) | `columns`, not stacked cards |
| Different failure handling scopes | `boundary-matrix` with failure, scope, and safety rationale |
| Architecture or data-flow shift | two-panel/swimlane `diagram`, never a single arrow chain |
| First-viewport ask/outcome summary | `summary-card` |
| Non-negotiable constraint or unresolved risk | `callout` |
| 3+ real alternatives before committing to an approach | `options-compare` |
| Load-bearing assumptions the design depends on | `assumption-list` |
| Final conceptual understanding check | `quiz` with 3–5 scored questions and answer rationales |
| Rendered UI / interaction change | describe the before/after in prose, or `columns` when the states summarize as fields |
