---
applies_to: Python projects (*.py)
skip_if: Working in TypeScript, C++, or any non-Python language
---

# Python

- Follow Google's Python style guide.
- Do not use timezone-naive datetimes, ever.
- Use type annotations wherever possible.
- Prefer `Self` from `typing_extensions` instead of forward-referencing the class name.
- When a function has two or more consecutive parameters of the same type, force keyword arguments using `*` to prevent accidental transposition.

  ```python
  def create_user(*, first_name: str, last_name: str, email: str) -> User: ...
  ```

- Prefer `ValidatedDataFrameMixin` (polars) over raw `pd.DataFrame` for typed schema validation.
- Use Pydantic dataclasses for external data needing validation. Use standard `dataclasses.dataclass` for internal, vetted data types.
- Prefer `frozen=True` on dataclasses where possible. Prefix internal fields with `_`.
- Use `MutableMapping` instead of `dict` for mutable dataclass fields.
- Prefer idiomatic dict operations: `.get(key, default)` over if/else lookups, `.pop()` over `del`.
- When logging exceptions, use the logger's `exception` method.
- When re-raising exceptions, use `raise e1 from e2` to preserve the original cause.
- New 3rd-party libraries must be added in conda-meta rather than depended on directly.

## Module Structure

- `interface.py` — defines the interface.
- `impl.py` — canonical implementation.
- `stub.py` — pure, IO-free stubbable implementation for testing.
- `__init__.py` — exports the above.

## Testing

- NEVER use fixtures. Use cached functions instead.
- Maximize code coverage using interfaces and stub implementations.
- Avoid IO in tests to prevent production load and flakiness.

## Dash

- Always use Desk Tools strongly typed callbacks.
- Separate heavy logic into a dedicated `api.py` module. Never do computation inside a callback.
- Organize composable UI blocks under a `components/` directory.
- Component rendering functions (returning a Dash `Component`):
  - Must be PascalCase.
  - Must be pure — no side effects, no callback registration inside them.
- Each component should have a `register_<feature>_callback` function.

