# Marimo Notebooks

- marimo requires every variable name to be globally unique across all cells in a notebook. Reusing a common name (e.g. `haircut`, `face_value`, `df`) in two different cells raises `MultipleDefinitionError` at runtime, not at write time, so it isn't caught by a type checker or linter.
- Default every cell-local variable to a leading underscore (e.g. `_face_value`, `_haircut`) unless another cell actually needs to reference it. Underscore-prefixed names are private to the cell and exempt from the uniqueness rule.
- Only leave a variable unprefixed if it's actually returned from the cell (`return foo,`) for another cell to depend on via a function parameter. Everything else defaults to private.
- All imports go in the `with app.setup:` block. No per-cell imports.
- Give each UI selector its own standalone cell — nothing else shares that cell. Don't bundle a selector's construction with the logic that consumes it.
- Precede each logical section with a markdown cell (`mo.md("## ...")`) naming what that section does, so the notebook reads top-to-bottom as a clear sequence of what to run.
