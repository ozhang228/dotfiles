# Local Visual Plan Authoring

Use this reference when authoring the local visual plan artifact for the brainstorm skill.

## Self-Contained Contract

- Keep plan content local. Read project context from local files and shell commands only.
- Do not install packages, run `npx`, fetch a remote block catalog, publish plan content, or depend on a bridge server.
- Use `./tmp/visual-plan-<slug>/` for scratch artifacts. Use `plans/<slug>/` only when the user explicitly wants the artifact checked in.
- The plan directory contains `index.html` as the primary review UI and `plan.md` as the source-of-truth text fallback. Optional assets must live inside the same folder.
- The HTML must be self-contained: inline CSS, no external CDN, no remote fonts, no remote scripts, and no runtime dependency outside a browser opening the file.
- Feedback comes through chat or file edits. Update the local files directly.

## Folder Shape

Use this structure:

```text
<plan-dir>/
  index.html
  plan.md
  assets/       # optional local images or generated files
```

## Static Review UI

`index.html` should be a focused review surface, not a marketing page:

- Header: title, status, scope, and last updated time if useful.
- Summary: objective, done criteria, and recommendation.
- Visual area: canvas-like sections, diagrams, before/after panels, or wireframes only when they help the user decide.
- File map: real files, symbols, data shapes, and ownership boundaries grounded in local code.
- Tradeoffs: committed choice plus meaningful alternatives.
- Expected behavior: 3-5 core behaviors and how they will be tested.
- Open questions: only decisions that would change the plan, with a recommended default.

Use stable ids for sections and questions so the user can refer to them in chat.

## Markdown Fallback

`plan.md` carries the same source content in plain Markdown for the agent. It does not need to duplicate every visual detail, but it must include enough section ids/headings that the HTML can be regenerated or corrected.

## Validation

Before handoff:

- Confirm `index.html` and `plan.md` exist.
- Read the generated files enough to catch placeholders, stale claims, contradictions, broken anchors, or missing expected sections.
- Run repo-native checks only when they already exist locally. Do not install validators.
- Report the folder path and direct `index.html` path.

## Visual Surface Choice

- Use no visual canvas for backend-only, architecture-only, data migration, copy-only, or otherwise non-visual work. Use document sections with inline diagrams, data models, file maps, or tables instead.
- Use a static visual area for one screen, component state, popover, before/after comparison, architecture map, or visual direction that does not need clicking.
- Use small inline JavaScript only when it materially improves reviewing tabs or toggles. Keep it local and readable in the HTML file.
- Keep product wireframes separate from architecture diagrams. Product screens should show app state; file paths, data contracts, risks, and implementation mechanics belong in document sections or annotations.

## Plan Body Shape

A useful local visual plan should stand alone:

1. Objective and done criteria.
2. Scope and explicit non-goals.
3. Proposed approach with key decisions and rationale.
4. File, symbol, API, or data-shape map grounded in real code.
5. Expected behaviors and verification.
6. Risks and assumptions.
7. Open questions at the bottom when answers would change the plan.

Use `references/document-quality.md` for the document quality bar. Read `references/canvas.md` before authoring a canvas-like visual area. Read `references/wireframe.md` before authoring any wireframe. Read `references/exemplar.md` when a worked example would help calibrate quality.
