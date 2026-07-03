# Local Visual Plan Authoring

Use this reference when authoring the local visual plan artifact for the brainstorm skill.

## Self-Contained Contract

- Keep plan content local. Read project context from local files and shell commands only.
- Do not install target-repo packages, execute remote packages, fetch a remote schema, publish plan content, or depend on any external server. The only package setup allowed during this workflow is the global renderer setup owned by `scripts/serve-mdx-visual-plan`.
- Use `./tmp/visual-plan-<slug>/` for scratch artifacts. Use `plans/<slug>/` only when the user explicitly wants the artifact checked in.
- The plan directory contains `plan.mdx` as the single authored source. Optional assets must live inside the same folder.
- Render `plan.mdx` with `scripts/serve-mdx-visual-plan <plan-dir> <port>`. That wrapper owns global setup through the skill's checked-in `assets/mdx-visual-plan-renderer/` package.
- MDX compiles to JavaScript, requires a JSX runtime, uses ESM-only packages, and needs Node.js 16 or later. The wrapper checks Node and installs the renderer package once, outside the target repo.
- Generated HTML, cache folders, or build outputs are renderer-owned and must not become a second hand-maintained source file.
- Feedback comes through chat or file edits. Update the local files directly.

## Folder Shape

Use this structure:

```text
<plan-dir>/
  plan.mdx
  assets/       # optional local images or generated files
```

## Rendered Review UI

The rendered `plan.mdx` should be a focused review surface, not a marketing page:

- `PlanHeader`: title, status, scope, and decision badges.
- `SummaryGrid` with `SummaryCard`: first-viewport outcome, hard guards, scope, and recommendation.
- `MetricGrid` with `Metric`: numeric or bounded facts such as call counts, cache keys, display units, and latency boundaries.
- `Split` with `Panel`: side-by-side decisions, tradeoffs, or current/target comparisons. Also the before/after primitive — two `Panel`s inside one `Split`.
- `Flow`: actual data flow or user flow. Use only when sequence matters.
- `FileMap`: real files, symbols, data shapes, and ownership boundaries grounded in local code. Pass `change` on an item (`added`/`modified`/`removed`/`renamed`) when the plan extends an existing file, not just for net-new ones.
- `TestMatrix`: 3-5 core behaviors and why each test exists.
- `Callout`: non-answerable risks, gates, hard constraints, or no-open-question statements.
- `Diff` / `AnnotatedCode`: real before/after code for a proposed change to an existing file, or the shape of a genuinely new file. See "Diff, data-model, and API components" below.
- `DataModel` / `Endpoint`: proposed schema or API contract, with per-field `change` flags.
- `Tabs` + `TabPanel`: group 3-8 related code/diff panels under one horizontal tab strip instead of stacking them.
- `DiagramNode` / `DiagramConnector` inside `Split`+`Panel`: a two-panel before/after architecture sketch — plain boxes, no diagram library.

Use stable ids for sections and questions so the user can refer to them in chat.

## Diff, data-model, and API components

These components exist because a plan is easier to review as structured,
scannable blocks than as prose describing a diff, a schema, or a contract —
the same idea `/code-review`'s recap uses for reviewing a diff, applied in
the forward direction (proposing a change instead of summarizing one). Full
prop types live in `assets/mdx-visual-plan-renderer/src/planComponents.tsx` —
read it before using any of these; the shapes below are a summary, not the
source of truth.

- **`Diff`** — proposed before/after for an existing file. Props: `filename`,
  optional `summary`, `before`/`after` (arrays of `{ ln?, type, code, note? }`
  where `type` is `"ctx" | "add" | "del" | "blank"`), optional `notes`
  (array of `{ n, text }`, cross-referenced by the line's `note` number).
  Use `"blank"` rows to keep the two panes line-aligned when one side has
  more lines than the other.
- **`AnnotatedCode`** — same visual language, one column, for a proposed
  brand-new file with no "before". Props: `filename`, optional `summary`,
  `lines` (array of `DiffLine`, usually all `type: "ctx"`), optional `notes`.
- **`DataModel`** — proposed entity/table. Props: `entity`, `fields` (array
  of `{ name, type, change?, was? }`). For a net-new entity every field is
  `change: "added"`; for extending an existing table, mix `added` on new
  columns with unflagged existing ones.
- **`Endpoint`** — proposed API contract. Props: `method`, `path`, optional
  `change`, optional `description`, optional `params` (array of
  `{ name, type, in?, change?, was? }`), optional `examples` (array of
  `{ label, json }` where `json` is a real JS value — it's rendered through
  `JSON.stringify(json, null, 2)` inside a native `<details>`, not hand-typed
  text).
- **`Tabs`** + **`TabPanel`** — `<Tabs><TabPanel label="...">...</TabPanel>...</Tabs>`.
  Each `TabPanel` needs a `label`; wrap `Diff`/`AnnotatedCode` blocks for the
  key files inside. Budget: 3-8 tabs — fewer doesn't need tabs, more stops
  being scannable.
- **`DiagramNode`** (optional `hot` prop to highlight the changed/new step)
  and **`DiagramConnector`** (defaults to `→`) — place inside two `Panel`s
  under one `Split` for a before/after architecture sketch. Use more `Panel`s
  for a swimlane with more than two tracks. Never collapse a structural
  change into a single node-to-node chain when panels/lanes would show it
  better.

### Proposed-change → component mapping

| Kind of proposed change | Component |
| --- | --- |
| New or modified schema/table | `DataModel`, field-level `change` |
| New or modified API/route | `Endpoint` with request/response examples |
| Modifying an existing file | `Diff` (split), one-line `summary`, a few `note`-numbered annotations |
| Proposing a brand-new file | `AnnotatedCode` instead of a one-sided diff |
| Several key files needing full proposed diffs | group under `Tabs`, 3-8 tabs |
| Before/after architecture or data-flow shift | `Split` + `Panel` + `DiagramNode`/`DiagramConnector`, never a single arrow chain |
| File footprint of a multi-file change | `FileMap` with `change` flags |
| Rendered UI/interaction change | wireframe — see `references/wireframe.md`, not a diagram |

## MDX Source

`plan.mdx` is the source-of-truth document for the user and the agent. Keep the prose, diagrams, structured sections, and open questions in that one file so revisions do not require syncing parallel HTML and Markdown.

MDX should make the plan easier to parse than Markdown. A plan that is mostly headings, paragraphs, and tables has failed the format choice. Put the first screen in `PlanHeader`, `SummaryGrid`, and `MetricGrid` when possible. Use prose for rationale, but move dense lists, decisions, flows, file maps, tests, and risks into renderer components.

### MDX is JSX, not HTML — inline markup must be JSX (FAILURE SEEN)

Any inline HTML you write in `plan.mdx` (e.g. a hand-built wireframe `<div>` block) is compiled as **JSX**, not HTML. Raw HTML attributes throw at client render and blank the **entire** page. Convert before writing:

- `class="..."` → `className="..."`
- `style="display:flex;gap:10px"` (string) → `style={{ display: "flex", gap: "10px" }}` (object; camelCase keys; every value a string except unitless numbers like `flex: 1`)
- `<input>` / `<br>` / self-closing icons → must be explicitly closed: `<input />`, `<span ... />`
- Literal `{`, `}`, or a bare `<` in text → wrap in a JSX expression or template string (`<pre>{\`{ "v": 1 }\`}</pre>`), or it parses as a JSX expression and errors.

Prefer the provided renderer components (`Split`/`Panel`, `Flow`, `FileMap`, etc.) over hand-rolled HTML wherever they fit — they're already valid JSX. Reach for inline JSX blocks only for genuine wireframe mockups, and write them as JSX from the start.

### Match each component's prop contract exactly (FAILURE SEEN)

Passing the wrong prop *shape* to a renderer component throws at render and blanks the **entire** page, with no server-side error. The bug seen: `PlanHeader badges` is typed `string[]`, but was passed objects `[{ label, tone }]` — React tried to render an object as a child and crashed the whole plan. Before using a component, open `assets/mdx-visual-plan-renderer/src/planComponents.tsx` and read its prop types. Known gotchas:

- `PlanHeader badges` — array of **plain strings**, not objects. No per-badge tone exists.
- `SummaryCard tone` — one of `default | good | warn | bad`. `Callout tone` — `info | good | warn | bad`. There is **no `"ok"` or `"info"` on SummaryCard**; an unknown tone silently yields a dead className (no crash, but no styling either), so it won't error but also won't look right.
- `Metric` takes `label` + `value` strings; `Flow steps` / `FileMap items` / `TestMatrix tests` each take arrays of objects with the exact keys defined in the file — anything else renders blank.
- `change` on `FileMap items` / `DataModel fields` / `Endpoint params` / `Endpoint` itself is one of `"added" | "modified" | "removed" | "renamed"` — exact strings, they're also the CSS badge class names.
- `Diff before`/`after` and `AnnotatedCode lines` are arrays of `{ ln?, type, code, note? }` — `type` must be exactly `"ctx" | "add" | "del" | "blank"`; any other string renders an unstyled row instead of failing loudly.
- `Endpoint examples[].json` takes a **real JS value** (object/array/string/number), not a JSON string — passing a string double-encodes it inside the `<pre>`.
- `Tabs` children must be `TabPanel` elements, each with a `label` prop — a bare `<div>` child inside `<Tabs>` is silently filtered out by `isValidElement`, so it just won't appear as a tab.

Rule: never pass a prop shape from memory. The component file is the source of truth; read it.

## Validation

Before handoff:

- Confirm `plan.mdx` exists.
- Read `plan.mdx` enough to catch placeholders, stale claims, contradictions, broken anchors, or missing expected sections.
- Check that the first viewport is componentized and scannable. If the page opens as a long text document, rewrite it with MDX components before handoff.
- Run `scripts/serve-mdx-visual-plan <plan-dir> <port>` and inspect the rendered page enough to catch obvious layout or navigation failures. If dependencies or renderer commands are missing, report that exact missing piece.
- **A `200` from `curl http://127.0.0.1:<port>/` does NOT mean the plan rendered, and neither does the compiled module.** The page is a client-rendered SPA: the server returns the ~500-byte Vite shell even when the MDX crashes the browser at render time and shows a blank page. Grepping the transformed module (`/.runtime/plan.mdx`) for `_createMdxContent` only proves it *parsed* — it does NOT catch render-time crashes like a bad prop shape (an object passed where a string is expected throws only when React renders it). That false-confidence check was the gap that let a blank page be reported as "verified."
- **Verify by actually rendering the plan through the real components (SSR).** This executes every component and throws on the exact errors a browser would. Drop a script *inside* `assets/mdx-visual-plan-renderer/` (so `vite`/`react` resolve) and run it with node:

  ```js
  // _ssr-check.mjs — run from inside assets/mdx-visual-plan-renderer/, then delete it
  import { createServer } from 'vite';
  import React from 'react';
  import { renderToStaticMarkup } from 'react-dom/server';
  const vite = await createServer({ server: { middlewareMode: true }, appType: 'custom', root: process.cwd() });
  try {
    const plan = await vite.ssrLoadModule('<ABSOLUTE_PATH>/plan.mdx');
    const comps = await vite.ssrLoadModule('./src/planComponents.tsx');
    const html = renderToStaticMarkup(React.createElement(plan.default, { components: comps.planComponents }));
    console.log('SSR_OK length=', html.length, 'HAS=', html.includes('<a distinctive phrase from your plan>'));
  } catch (e) { console.log('SSR_ERROR:', e.message); }
  finally { await vite.close(); }
  ```

  A clean run prints `SSR_OK length=<thousands> HAS= true`. `SSR_ERROR: ...` (e.g. "Objects are not valid as a React child") is the real failure the `200`/grep checks miss. Only proceed to serving after an `SSR_OK` with your content present.
- **The SSR check is a headless crash test, not a preview — it has no JavaScript.** It proves the components render without throwing; it does NOT prove `Tabs` clicking works, JSON `<details>` disclosure opens, or any other interaction — `renderToStaticMarkup` produces dead HTML with no event handlers attached. Never hand the SSR output to the user as "the plan." Delete the check script after running it.
- Run repo-native checks only when they already exist locally. Do not install validators.
- **The one artifact the user actually reviews is the live `scripts/serve-mdx-visual-plan` URL.** After the SSR check passes, run it (or confirm it's already running) and verify the `http://127.0.0.1:<port>/` URL responds. This is a real Vite dev server serving hydrated React — tabs, disclosure, and any future interactive component work there. Report that URL, the folder path, and the direct `plan.mdx` path. If you only ever showed the user an SSR snapshot, you have not shown them the plan.

## Visual Surface Choice

- Use no visual canvas for backend-only, architecture-only, data migration, copy-only, or otherwise non-visual work. Use document sections with inline diagrams, data models, file maps, or tables instead.
- Use a static visual area for one screen, component state, popover, before/after comparison, architecture map, or visual direction that does not need clicking.
- Use small inline JavaScript only when it materially improves reviewing tabs or toggles. Keep it local and readable inside the MDX artifact or renderer-supported component.
- Keep product wireframes separate from architecture diagrams. Product screens should show app state; file paths, data contracts, risks, and implementation mechanics belong in document sections or annotations.

## Plan Body Shape

A useful local visual plan should stand alone:

1. Objective and done criteria.
2. Scope and explicit non-goals.
3. Proposed approach with key decisions and rationale.
4. File, symbol, API, or data-shape map grounded in real code.
5. Performance boundaries for batching, caching, latency, and external I/O when they matter.
6. Expected behaviors and verification.
7. Risks and assumptions.
8. Open questions at the bottom when answers would change the plan.

The body shape describes content, not rendering. Use MDX components for the sections where visual grouping helps the reviewer scan, compare, or verify the plan.

Use `references/document-quality.md` for the document quality bar. Read `references/canvas.md` before authoring a canvas-like visual area. Read `references/wireframe.md` before authoring any wireframe. Read `references/exemplar.md` when a worked example would help calibrate quality.
