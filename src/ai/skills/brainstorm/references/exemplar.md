# Good vs. bad exemplar

The calibration bar for a plan rendered through our real local MDX renderer
(`assets/mdx-visual-plan-renderer/`) — the actual component set, not an
aspirational one. Read `references/visual-plan.md` for the component API
before comparing against this.

**GOOD.** A backend change — rotating refresh tokens on session renewal.
Opens with a sentence of prose: The Ask. Then `BehaviorMatrix` naming the core
behaviors and why each needs a test, invariant, or manual check. It names the
unit of work and shows the smallest before/after refresh scenario before any
file list. Then `AssumptionList` with
one item honestly flagged `unverified` (needs a grep across other repos)
instead of buried in prose as an accepted fact. Then Approach: `OptionsCompare`
weighing rotate-vs-extend with a `recommended` pick, a `Split`+`Panel` diagram
sketch of the before/after flow, `DataModel` showing the schema delta with
`change` flags, `Endpoint` with a real JSON response example, and a `Tabs`
block holding the `Diff`/`AnnotatedCode` for the two load-bearing files. Ends
with `FileMap`. If refresh failures have different recovery scopes, it includes
a `BoundaryMatrix`; otherwise it omits the component. No title, category-tag
badges, or marketing framing because the Ask already opened the document.

**BAD.** A title and category badges that restate the Ask paragraph. A wall of Markdown prose
where `DataModel`/`Endpoint`/`Diff` should be — describing a schema change in
a paragraph instead of rendering it as a field table with `change` flags. An
`AssumptionList` item stated as settled fact in prose instead of flagged
`unverified`/`todo`. A `Tabs` block with more than 8 panels, or fewer than 3
(just don't use tabs then). A plan that opens with scope/non-goals/objective
headers before ever stating the ask in one sentence.
