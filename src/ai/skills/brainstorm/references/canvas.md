# Canvas & artboard placement — single source of truth

This file is the canonical guide for how the visual-plan canvas works: artboard
placement, lane layout, annotations, patching, and the legacy kit tree. Read it
in full before authoring or editing any canvas/artboard content; do not author
canvas layouts from memory or paraphrase these rules per mode.

<!-- SHARED-CORE:canvas-surface START -->

**The coordinate rule.** The `surface` locks each artboard's footprint and
aspect — never set artboard width/height and never use coordinates inside the
wireframe HTML; board-level artboard `x`/`y` IS allowed when it creates clear
lanes. Let canvas auto-placement handle simple one-row boards.

**Lay out mixed canvases in lanes.** When a canvas contains broad browser /
desktop frames plus compact `mobile`, `popover`, or `panel` surfaces, do not put
everything in one horizontal strip. Use board-level artboard `x`/`y` to reserve
lanes with generous empty space: main flow on one row, compact surfaces in their
own column or row, and loading/error states in a lower row. Keep at least 96px
between rendered artboard rectangles plus room for annotation gutters; when a
broad browser/desktop frame sits beside a compact panel/popover, leave at least
160px so frame borders, labels, and hover controls never touch. Connect only
neighboring steps; never draw a long connector that skips across unrelated
frames. Connector labels must sit in open canvas space. If the label would touch
or cross either artboard, remove the label and explain the transition with a
nearby annotation instead. Before handoff, inspect the top canvas at default zoom
and move any frame whose label, connector, or annotation crosses another frame.

**Board-unit spacing defaults.** The canvas coordinate system uses approximately 2 board units per screen pixel. `browser` frames occupy roughly 700 × 600 board units; `desktop` frames roughly 900 × 700 board units. Apply these minimum x/y gaps when placing frames explicitly — any less and frames will touch or overlap:

- x-gap between `browser` frames: **≥ 1100** (700-unit frame + 400-unit gutter)
- x-gap between `desktop` frames: **≥ 1300** (900-unit frame + 400-unit gutter)
- y-gap between rows of any surface: **≥ 1400** (includes frame height + section header + buffer)

When in doubt, use larger values — the canvas auto-zooms to fit everything.

**Canvas annotations are designer notes on the artboard.** When a top canvas is
present, sprinkle Figma-style notes near the frames they explain: a short
heading, supporting text, and bullets — plain text layers, never bordered or
shadowed cards, and never a box around a frame. The renderer spaces notes away
from frames, so place each note by the frame it describes. Use an arrow only to
point at one specific control or transition; for a broad frame-level note, write
text beside the frame with no connector. Connectors are for real sequences only —
never fake "Step 1 → Step 2" lines between independent states.

**Do not create overlapping annotations.** Anchor each ordinary note to the
frame it explains with `targetId` + `placement` (top/right/bottom/left), and
omit `type` or use `type: "note"`. The renderer parks notes in a gutter beside
the frame and lays them out automatically. Do not use `type: "callout"`,
`type: "text"`, `type: "arrow"`, x/y, or points for ordinary notes; those are
freeform review-markup layers and must be reserved for intentional markup in
open canvas space. Reserve arrows for a note that must point at one specific
control inside a frame; a note that simply sits beside its frame needs no arrow.

**Patching.** Edit one wireframe, canvas annotation, diagram, or section directly in `index.html` and mirror the source text in the Markdown fallback. Prefer a targeted find/replace against a unique snippet over regenerating the whole artifact. If a broad rewrite is unavoidable, reread the full current `index.html` and Markdown fallback first, carry forward every existing section, and inspect the result before handoff.

**Never emit a titled artboard with no interior wireframe content.** Every artboard you place on the canvas must carry real HTML wireframe content. A label-only frame is empty. If you only have a title, write it as a section header or annotation, not an empty artboard.

**UI mockups belong in the top visual review area.** Static UI/product visuals
live on the canvas; multi-step UI flows get both canvas wireframes and a
prototype. When the user asks for a mockup, UI state, loading state, layout,
screen, or visual comparison, make the canvas the primary home for that static
visual. When the user asks for a prototype or the plan contains a sequence the
reviewer must feel, keep the canvas artboards and add `a local prototype section` so the
top surface shows Wireframes / Prototype tabs. Architecture/code diagrams stay
inline in the document (the local visual authoring reference owns that rule) unless the user explicitly asks for a spatial board. Document sections
can explain, compare, or map implementation, but they should not host the
primary UI mockup or prototype just because `custom HTML`, screenshots, or prose
are easier to produce. If the canvas/prototype surface cannot represent the
requested UI fidelity, still keep the closest top-surface representation and
call out or extend the needed renderer capability. A skeleton/loading mockup
also lives in a canvas artboard — never move a mockup out of the canvas.

**Storyboards are canvas artifacts, not document diagrams.** When the requested
output is a product flow, onboarding journey, "light storyboard", or canvas
wireframe, author the flow as multiple top-canvas artboards with real screen
content and neighboring connectors. Keep document-body `diagram` blocks for
architecture and mechanics that are not themselves user-visible screens. A
storyboard made from a single inline HTML diagram is the wrong surface.

For abstract product concepts, use the canvas to create the first "I get it"
moment: one real app state near the top showing how the concept appears to a
user, followed by separate annotations or diagrams for mechanics. Do not make
the first artboard a hybrid of app UI and architecture notes; the app screen
should be inspectable as product UI on its own.

**Legacy kit tree.** Older plans set a `screen` array of `{ el, ...props }` kit
nodes instead of `html`; the renderer still accepts and displays it so saved
plans round-trip, but new plans emit `html`. Do not author fresh kit-tree
screens, and do not put nested kit components such as `<FrameScreen>`, `<Card>`,
`<Row>`, `<Title>`, or `<Btn>` inside a canvas `<Screen>`. A new canvas artboard
with kit-tree children is a defect: replace it with
`<Screen surface="..." html={...} />` using the HTML wireframe rules. The HTML
path is the one that gets the renderer-owned surface sizing, theme tokens,
sketch/clean toggle, and safe text layout used by good document-body
wireframes. Likewise, old or imported plans may carry coordinate-based regions
or free-float x/y on notes; those are legacy escape hatches the renderer still
shows but you must never produce. The gutter parks notes by `targetId` +
`placement`, and the coordinate rule at the top of this file governs all
new-plan placement.

<!-- SHARED-CORE:canvas-surface END -->
