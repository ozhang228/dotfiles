# Local Visual Recap Authoring

Use this reference when authoring the local visual recap artifact for code review.

## Self-Contained Contract

- Keep recap content local. Read diff, stat, and source context from local files and shell commands only.
- Do not install packages, execute remote packages, fetch a remote schema, publish recap content, or depend on any external server.
- Use `./tmp/review-<branch-name>-recap/` for scratch artifacts. Use `plans/<slug>/` only when the user explicitly wants the artifact checked in.
- The recap directory contains `index.html` as the primary review UI and `review.md` as the source-of-truth text fallback. Optional assets must live inside the same folder.
- The HTML must be self-contained: inline CSS, no external CDN, no remote fonts, no remote scripts, and no runtime dependency outside a browser opening the file.
- Feedback comes through chat or file edits. When the user references a recap item, update code and local review files directly.

## Folder Shape

Use this structure:

```text
<plan-dir>/
  index.html
  review.md
  assets/       # optional local images or generated files
```

## Static Review UI

`index.html` should make the review easier to scan than terminal comments:

- Header: branch, base, review date if useful, and which agents ran/skipped.
- Architecture verdict: the confirmed direction and modeling judgment.
- Findings summary: counts by Bugs, Testing, Performance, Simplification, and Nits.
- File footprint: changed files with short notes and change type.
- Finding sections: each finding has a stable id, severity, file/line, concrete ask, and old/new code or question.
- Key changes: 3-8 focused diff or annotated-code panels for load-bearing files.
- Schema/API summaries when contracts changed.
- Wireframes only when rendered UI changed.

Use stable ids like `bug-1`, `test-2`, or `simplification-1` so the user can reference findings from the UI in chat.

## Markdown Fallback

`review.md` carries the same source content in plain Markdown for the agent and for easy regeneration. It should keep the same stable ids used in `index.html`.

## Validation

Before handoff:

- Confirm `index.html` and `review.md` exist.
- Read the generated files enough to catch placeholders, stale claims, contradictions, broken anchors, or missing expected sections.
- Run repo-native checks only when they already exist locally. Do not install validators.
- Report the folder path and direct `index.html` path.

## Recap Shape

A useful review recap should show the work unit at a higher altitude than raw diff while preserving enough evidence to act:

1. UI-impact headline first, only when rendered UI changed.
2. Short outcome narrative: what changed and why.
3. Schema, data-model, API, or route summaries when those contracts changed.
4. File-tree footprint with per-file change notes.
5. Key changes section with 3-8 focused diff or annotated-code panels for load-bearing files.
6. Grouped review findings with stable ids matching the Markdown review file.

Keep the recap substantial but not exhaustive. A change worth recapping should include a file tree and key-change evidence. Skip a visual recap for tiny diffs that review faster as plain diff.

## Diff To Section Mapping

- Schema or migration change: show resulting entities, fields, and relations. Include old values when the diff changed a field type, name, or relationship.
- API, action, or route change: show method, path, params, request, and responses grounded in the diff.
- Compatibility-sensitive change: add a short note near the relevant data/API section and pair it with a focused diff.
- Meaningful code hunk: show real before/after text, filename, language, summary, and a few high-signal annotations.
- Brand-new file or new substantial block: show annotated code with the real new code and margin notes.
- Files added, removed, renamed, or modified: show a file tree with change flags and short notes.
- Rendered UI or interaction change: use wireframes. Prefer before/after when comparison clarifies the change; use after-only or state sequence when that fits better.
- Architecture or data-flow shift: use a two-dimensional diagram, such as before/after panels, layers, swimlanes, dependency maps, or grouped regions.

## UI Recap Coverage

When rendered UI changed, identify the changed entry surface, interaction surface, destination or persistent state, and role/access variants. Show the smallest wireframe set that makes that review clear. Read `references/wireframe.md` before authoring any wireframe and `references/canvas.md` before authoring a canvas-like visual area.

## Grounding And Redaction

Structured sections are only useful if derived from the actual changed lines. Use real paths, fields, methods, payload shapes, and before/after text. Mark anything inferred as inferred in prose. Redact secrets or credential-looking values before copying snippets, diffs, examples, or prose into the recap.
