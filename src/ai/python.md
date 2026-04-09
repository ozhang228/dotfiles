---
applies_to: Python projects (*.py)
skip_if: Working in TypeScript, C++, or any non-Python language
---

# Python

- Follow Google's Python style guide.
- Do not use timezone-naive datetimes, ever.
- Use type annotations wherever possible.
- When a function has two or more consecutive parameters of the same type, force keyword arguments using `*` to prevent accidental transposition.

  ```python
  # Good — callers must use keywords, preventing mix-ups.
  def create_user(*, first_name: str, last_name: str, email: str) -> User: ...

  # Bad — easy to accidentally swap arguments.
  def create_user(first_name: str, last_name: str, email: str) -> User: ...
  ```
- Use Pydantic dataclasses for external data needing validation. Use standard `dataclasses.dataclass` for internal, vetted data types.
- Prefer `frozen=True` on dataclasses where possible. Prefix internal fields with `_`.
- Use `MutableMapping` instead of `dict` for mutable dataclass fields to make mutability intent explicit.
- Prefer idiomatic dict operations: `.get(key, default)` over if/else lookups, `.pop()` over `del`.
- When logging exceptions, use the logger's `exception` method so the type and full stack trace are included.
- When re-raising exceptions, use `raise e1 from e2` to preserve the original cause.
- New 3rd-party libraries must be added in conda-meta rather than depended on directly.

## Module Structure

Every module should follow this layout:

- `interface.py` — defines the interface.
- `impl.py` — canonical implementation.
- `stub.py` — pure, IO-free stubbable implementation for testing.
- `__init__.py` — exports the above.

## Testing

- NEVER use fixtures. Fixtures are dependency-injected and implicit. Use cached functions instead.
- Maximize code coverage using interfaces and stub implementations.
- Avoid IO in tests to prevent production load and flakiness.

## Dash

- Always use Desk Tools strongly typed callbacks.
- Separate heavy logic into a dedicated `api.py` module. Never do computation-heavy tasks inside a callback.
- Organize composable UI blocks under a `components/` directory.
- Component rendering functions (returning a Dash `Component`):
  - Must be PascalCase.
  - Must be pure — no side effects, no callback registration inside them.
- Each component should have a `register_<feature>_callback` function to hook callbacks to the Dash instance.
- Registered callbacks should depend entirely on predefined input/output models, making them fully testable without a running Dash app.
