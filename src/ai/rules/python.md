---
applies_to: Python projects (*.py)
skip_if: Working in TypeScript, C++, or any non-Python language
---

# Python

- Follow Google's Python style guide.
- Do not use timezone-naive datetimes, ever.
- Prefer inferred types per `general.md`; annotate parameters, empty collections, ambiguous values, and other places where the type checker cannot recover the intended type.
- Prefer `Self` from `typing_extensions` instead of forward-referencing the class name.
- When a function has two or more consecutive parameters of the same type, force keyword arguments using `*` to prevent accidental transposition.

  ```python
  def create_user(*, first_name: str, last_name: str, email: str) -> User: ...
  ```

- Use keyword arguments at call sites when two consecutive parameters share a type or the function takes more than three parameters.

- Prefer `ValidatedDataFrameMixin` (polars) over raw `pd.DataFrame` for typed schema validation.
- Use Pydantic dataclasses for external data needing validation. Use standard `dataclasses.dataclass` for internal, vetted data types.
- Do not use `typing.Annotated`. For Pydantic constraints, declare the type normally and assign `Field(...)`, for example `count: int = Field(gt=0)`.
- Prefer `frozen=True` on dataclasses where possible. Prefix internal fields with `_`.
- Put logic fully owned by a dataclass on the dataclass. If a value is completely determined by the instance's other fields, expose it as a property instead of passing or recomputing it at construction sites. Keep it stored when it carries independent state that cannot be reconstructed.

  ```python
  @dataclass(frozen=True)
  class StringMetricValue:
      value: str | None
      errors: frozenset[str]

      @property
      def status(self) -> StringMetricStatus:
          if self.errors:
              return StringMetricStatus.ERROR
          if self.value is None:
              return StringMetricStatus.MISSING
          return StringMetricStatus.OK
  ```

- Use `MutableMapping` instead of `dict` for mutable dataclass fields.
- In return signatures and data type fields, prefer the widest read-only collection interface that expresses the contract (`Sequence` over `list` or `tuple[T, ...]`, `frozenset` over `set`, `Mapping` over `dict`). Use a tuple type when fixed length or positional meaning is part of the contract, and mutable interfaces only when callers must mutate.
- Prefer idiomatic dict operations: `.get(key, default)` over if/else lookups, `.pop()` over `del`.
- Don't manually splice batch results into input order with `iter()` and `next()`. Track input indices and pair results with `zip(..., strict=True)` so ordering is explicit.
- When logging exceptions, use the logger's `exception` method.
- When re-raising exceptions, use `raise e1 from e2` to preserve the original cause.
- New 3rd-party libraries must be added in conda-meta rather than depended on directly.
- Every `match` statement must end with `case _: assert_never(x)` on the matched value. This makes adding a new union/enum variant a type error at every call site, instead of silently falling through. Applies even when the match looks exhaustive today — future variants are the point.

  ```python
  match payoff:
      case OptionPayoffType.CALL: ...
      case OptionPayoffType.PUT: ...
      case OptionPayoffType.STRADDLE: ...
      case _:
          assert_never(payoff)
  ```

## Module Structure

- `interface.py` — defines the interface.
- `impl.py` — canonical implementation.
- `stub.py` — pure, IO-free stubbable implementation for testing.
- `__init__.py` — exports the above.

## Testing

- NEVER use fixtures. Use cached functions instead.
- Maximize code coverage using interfaces and stub implementations.
- Avoid IO in tests to prevent production load and flakiness.
- See `general.md`'s "Recurring bad-test patterns" for the cross-language test-quality checklist (vacuous assertions, tautological/trivial-by-default tests, redundant coverage, brittle-to-refactor tests, unverified test names and secondary inputs).

## Dash

- Always use Desk Tools strongly typed callbacks.
- Separate heavy logic into a dedicated `api.py` module. Never do computation inside a callback.
- Organize composable UI blocks under a `components/` directory.
- Component rendering functions (returning a Dash `Component`):
  - Must be PascalCase.
  - Must be pure — no side effects, no callback registration inside them.
- Each component should have a `register_<feature>_callback` function.
