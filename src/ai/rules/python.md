---
applies_to: Python projects (*.py)
skip_if: Working in TypeScript, C++, or any non-Python language
---

# Python

- Do not use timezone-naive datetimes
- Prefer `Self` from `typing_extensions` instead of forward-referencing the class name.
- When a function has two or more consecutive parameters of the same type, force keyword arguments using `*` to prevent accidental transposition.
- Use keyword arguments at call sites when two consecutive parameters share a type or the function takes more than three parameters.
- Prefer `ValidatedDataFrameMixin` (polars) over raw `pd.DataFrame` for typed schema validation.
- Use Pydantic dataclasses for external data needing validation. Use standard `dataclasses.dataclass` for internal, vetted data types.
- Do not use `typing.Annotated`. For Pydantic constraints, declare the type normally and assign `Field(...)`
- Prefer `frozen=True` on dataclasses where possible. Prefix internal fields with `_`.
- Put logic fully owned by a dataclass on the dataclass. If a value is completely determined by the instance's other fields, expose it as a property instead of passing or recomputing it at construction sites
- Use `MutableMapping` instead of `dict` for mutable dataclass fields.
- For function parameters, return types, and dataclass or Pydantic fields, use the widest read-only collection type that preserves the required invariants. Prefer `Sequence[T]` over `list[T]` or `tuple[T, ...]`, and `Mapping[K, V]` over `dict[K, V]`, when every permitted implementation is valid.
- A read-only interface does not guarantee an immutable value: `Sequence[T]` can be a mutable `list[T]`. Python has no general frozen-sequence type, so use `tuple[T, ...]` when ordered values must be immutable or hashable, including fields on frozen objects used as mapping or cache keys. Use `frozenset[T]` when unordered values must be immutable.
- Prefer idiomatic dict operations: `.get(key, default)` over if/else lookups, `.pop()` over `del`.
- Don't manually splice batch results into input order with `iter()` and `next()`. Track input indices and pair results with `zip(..., strict=True)` 
- When re-raising exceptions, use `raise e1 from e2` to preserve the original cause.
- In projects that use UV, run `uv lock` after adding, removing, or changing a dependency and include the regenerated `uv.lock` in the same change.
- Every `match` statement must end with `case _ as unreachable: assert_never(unreachable)` on the matched value. This adds exhaustive matching
- Keep internal-package `__init__.py` files empty. Re-export names from `__init__.py` only when the package intentionally defines a public-facing library API.

## Testing

- Don't use fixtures. 
- Maximize code coverage using interfaces and stub implementations.
- Avoid IO in tests 

## Dash

- Always use Desk Tools strongly typed callbacks.
- Separate heavy logic into a dedicated `api.py` module. Never do computation inside a callback.
- Organize composable UI blocks under a `components/` directory.
- Component rendering functions (returning a Dash `Component`):
  - Must be PascalCase.
  - Must be pure — no side effects, no callback registration inside them.
- Each component should have a `register_<feature>_callback` function.
