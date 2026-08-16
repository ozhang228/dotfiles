# Jupyter

- Use `NotebookEdit` for cell changes, never raw `json.load`/`json.dump`.
- `NotebookEdit` writes `source` as one collapsed string. Convert touched cells back to this repo's line-list form after editing, preserving content byte-for-byte:

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

- Only convert cells whose `source` is currently a string.
- `ensure_ascii=False` is mandatory in `json.dump`.
- Diff the non-edited cells against pre-edit state after converting.
- Run `black --ipynb` on touched notebooks before finishing.
- If `black --ipynb` reports missing Jupyter dependencies, check sibling conda envs for `tokenize-rt` before adding it to a shared lockfile.
