# Structured review blocks

This file is the canonical component library for turning a diff into the
self-contained HTML used by code-review recaps. The brainstorm renderer mirrors
the same concepts in React, but its prop contracts live in
`assets/mdx-visual-plan-renderer/src/planComponents.tsx`. Read this file in full
before authoring recap blocks; do not improvise diff or data-model
markup per review.

**Why plain HTML here.** A code-review recap is a static file opened directly
in a browser, with no build step or external dependency. Every block below is
plain HTML + CSS, with vanilla JS only where interactivity earns its keep
(`<details>` disclosure). The diff text is already available, so no
client-side diffing library is needed.

**Copy the CSS once per artifact.** Paste the full token + component CSS block
below into the recap's own `<style>` tag. Do not link it externally, do
not partially copy classes — an artifact missing a class it references is a
broken artifact. Fill in real content; never ship the example values.

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
<nav class="section-nav" aria-label="Review sections">
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

## Block: data model (`data-model`)

Schema/migration changes. Field-level change flags with `was →` for anything
that changed shape — this is the headline for a schema change; reach for a
literal SQL diff only when the exact statement still matters.

```css
.data-model { padding: 16px 18px; }
.data-model .entity-name { font-family: var(--mono); font-size: 14px; font-weight: 700; margin: 0 0 12px; }
.field-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.field-table th { text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); font-weight: 600; padding: 0 10px 6px 0; border-bottom: 1px solid var(--line); }
.field-table td { padding: 7px 10px 7px 0; border-bottom: 1px solid var(--line); vertical-align: top; }
.field-table tr:last-child td { border-bottom: none; }
.field-table .fname { font-family: var(--mono); }
.field-table .ftype { font-family: var(--mono); color: var(--muted); }
.field-table .was { color: var(--muted); text-decoration: line-through; font-family: var(--mono); font-size: 12px; }
.field-table .arrow { color: var(--muted); margin: 0 4px; }
```

```html
<div class="card data-model">
  <p class="entity-name">sessions</p>
  <table class="field-table">
    <thead><tr><th>field</th><th>type</th><th>change</th></tr></thead>
    <tbody>
      <tr><td class="fname">id</td><td class="ftype">uuid</td><td></td></tr>
      <tr><td class="fname">refresh_token_hash</td><td class="ftype">text</td><td><span class="badge added">added</span></td></tr>
      <tr><td class="fname">expires_at</td><td class="ftype">timestamptz</td><td><span class="badge modified">modified</span> <span class="was">not null</span><span class="arrow">→</span>nullable</td></tr>
      <tr><td class="fname">legacy_token</td><td class="ftype"><span class="was">text</span></td><td><span class="badge removed">removed</span></td></tr>
    </tbody>
  </table>
</div>
```

For a forward plan (brainstorm), the same card proposes the new entity —
every row just carries `added` since nothing exists yet, or the mix of
`added`/`modified`/`unchanged` when the plan extends an existing table.

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
  <p class="endpoint-desc">One-sentence description grounded in the diff.</p>
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
labeled `<details>` rather than concatenating shapes into one block. Mark a
removed/changed param inline the same way a data-model field does
(`badge` + `.was` + arrow).

## Block: before/after columns (`columns`)

Structured side-by-side comparison — for contract shape, not pixels. Nest any
other block (commonly `data-model` or `api-endpoint`) inside each column.

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
lines, which `columns` cannot. Don't stack two `data-model` cards vertically
and call it a comparison when this grid exists.

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

Use real failure modes and observed handling from the diff. Do not infer that
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

## Grounding rule

Every block in this file is **true by construction** only if built
mechanically from the real diff (or, for a forward plan, the real code being
extended) — real paths, real fields, real method/path, real before/after
text. Never invent, round, or approximate a value inside a structured block.
Prose (`rich-text`/plain paragraphs) is the only place free-form judgment,
narrative, and risk assessment belong. A confidently wrong structured block is
worse than no block: a reviewer who trusts the summary may skip the exact
line the summary got wrong.

## Choosing a block for a change

| Kind of change | Block |
| --- | --- |
| Schema or migration change | `data-model`, field-level `change` flags |
| API / action / route change | `api-endpoint` with request/response examples |
| Any meaningful code hunk | `diff` (split), one-line `summary`, a few `note-marker` annotations on load-bearing lines |
| Brand-new file / substantial new block | `annotated-code` instead of a one-sided diff |
| Structured before/after (schema/contract shape) | `columns`, not stacked cards |
| Different failure handling scopes | `boundary-matrix` with failure, scope, and safety rationale |
| Architecture or data-flow shift | two-panel/swimlane `diagram`, never a single arrow chain |
| Rendered UI / interaction change | describe the before/after in prose, or `columns` when the states summarize as fields |
