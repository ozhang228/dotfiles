# Jupyter Notebooks (.ipynb)

- Always use the `NotebookEdit` tool for cell changes. Never hand-roll edits via raw `json.load`/`json.dump` — reserializing the whole file collapses formatting and produces multi-thousand-line diffs for a single-cell content change.
- `NotebookEdit` itself writes a cell's `source` as one collapsed string, not this repo's usual list-of-lines form (`["line1\n", "line2\n", ...]`). Both are valid nbformat and render identically in Jupyter, but the collapsed form turns the whole cell into one unreadable diff line and can hide real changes on review. After editing a notebook, check whether the touched cells' `source` fields are strings and convert them back to line-lists, preserving content byte-for-byte:

  ```python
  import json

  def string_to_lines(s: str) -> list[str]:
      lines = s.split("\n")
      return [
          line + "\n" if i < len(lines) - 1 else line
          for i, line in enumerate(lines)
          if i < len(lines) - 1 or line
      ]

  with open(path, encoding="utf-8") as f:
      nb = json.load(f)
  for cell in nb["cells"]:
      if isinstance(cell.get("source"), str):
          cell["source"] = string_to_lines(cell["source"])
  with open(path, "w", encoding="utf-8") as f:
      json.dump(nb, f, indent=1, ensure_ascii=False)
      f.write("\n")
  ```

  Only convert cells whose `source` is currently a string — leave list-form cells untouched, or the full-file reserialize will touch every cell's whitespace/indent and blow up the diff.
  **`ensure_ascii=False` is mandatory.** `json.dump`'s default (`ensure_ascii=True`) silently rewrites every non-ASCII character in the *entire file* — not just the cells you're touching — into `\uXXXX` escapes (real case: `─`, `€`, `–`, and an emoji surrogate pair all got mangled this way across 5 notebooks in one pass). The escapes are valid JSON and `json.load` still round-trips them correctly, but they no longer render as the original character when read directly, and they silently corrupt cells you never meant to touch.
- After converting, diff the *other* (non-edited) cells in the file against their pre-edit state (or `origin/master`) to confirm the reserialize didn't touch anything beyond the cells you meant to change.
- Run the repo's notebook formatter (e.g. `black --ipynb`) on any touched notebook before calling the edit done — it catches real reformatting needs (unwrapped long lines, stray blank lines after `def`/magics) that plain content edits don't.
- If `black --ipynb` reports "Jupyter dependencies are not installed" in the active venv, check sibling environments (a project's conda env) for `tokenize-rt` before adding it to a shared `pyproject.toml`/lockfile — it's often already present there.
