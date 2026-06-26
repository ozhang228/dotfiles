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
- `Split` with `Panel`: side-by-side decisions, tradeoffs, or current/target comparisons.
- `Flow`: actual data flow or user flow. Use only when sequence matters.
- `FileMap`: real files, symbols, data shapes, and ownership boundaries grounded in local code.
- `TestMatrix`: 3-5 core behaviors and why each test exists.
- `Callout`: non-answerable risks, gates, hard constraints, or no-open-question statements.

Use stable ids for sections and questions so the user can refer to them in chat.

## MDX Source

`plan.mdx` is the source-of-truth document for the user and the agent. Keep the prose, diagrams, structured sections, and open questions in that one file so revisions do not require syncing parallel HTML and Markdown.

MDX should make the plan easier to parse than Markdown. A plan that is mostly headings, paragraphs, and tables has failed the format choice. Put the first screen in `PlanHeader`, `SummaryGrid`, and `MetricGrid` when possible. Use prose for rationale, but move dense lists, decisions, flows, file maps, tests, and risks into renderer components.

## Validation

Before handoff:

- Confirm `plan.mdx` exists.
- Read `plan.mdx` enough to catch placeholders, stale claims, contradictions, broken anchors, or missing expected sections.
- Check that the first viewport is componentized and scannable. If the page opens as a long text document, rewrite it with MDX components before handoff.
- Run `scripts/serve-mdx-visual-plan <plan-dir> <port>` and inspect the rendered page enough to catch obvious layout or navigation failures. If dependencies or renderer commands are missing, report that exact missing piece.
- Run repo-native checks only when they already exist locally. Do not install validators.
- Verify the `http://127.0.0.1:<port>/` URL responds, and report the verified URL with the folder path and direct `plan.mdx` path.

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
