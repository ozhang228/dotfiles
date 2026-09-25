---
applies_to: Python projects (*.py)
skip_if: Working in TypeScript, C++, or any non-Python language
---

# Python

- Do not use timezone-naive datetimes
- Prefer `Self` from `typing_extensions` instead of forward-referencing the class name.
- When an API returns `fio.result.Result`, represent expected failures as `Err` and propagate them through reusable code without unwrapping; unwrap once at the application or top-level boundary.
- When a function has two or more consecutive parameters of the same type, force keyword arguments using `*` to prevent accidental transposition.
- Use keyword arguments at call sites when two consecutive parameters share a type or the function takes more than three parameters.
- Prefer `ValidatedDataFrameMixin` (polars) over raw `pd.DataFrame` for typed schema validation.
- Use Pydantic dataclasses for external data needing validation. Use standard `dataclasses.dataclass` for internal, vetted data types.
- Parse external JSON into Pydantic domain models at the source boundary. Keep decoded raw values local to parsing; do not pass `JsonValue` or recursive JSON aliases through internal APIs.
- Do not use `typing.Annotated`. For Pydantic constraints, declare the type normally and assign `Field(...)`
- When extending a `Protocol`, list `Protocol` in the bases as well. Inheriting only from another protocol creates a nominal class, so structural test stubs will not satisfy it.
- Prefer `NewType` over a plain type alias for semantically distinct scalar or identifier values that the type checker should reject when interchanged. Keep ordinary aliases for structural shapes, unions, and readability-only abbreviations where nominal distinction is not intended.
- Model domain meaning at the element level. For a one-use container shape, name its meaningful element types and inline the container at the use site, such as `tuple[ColumnName, Operator, Boundary]`; do not alias the whole container merely to shorten an annotation. Name the collection itself only when it is a reusable domain concept with collection-level meaning or invariants. For example, define `UnderlyingPrice = NewType("UnderlyingPrice", float)` and annotate an immutable collection as `tuple[UnderlyingPrice, ...]` instead of introducing `UnderlyingPrices = tuple[float, ...]`.
- Do not move an existing domain type solely so a new consumer can share it. Preserve the current owner's API when dependency direction permits; when lower-level reusable logic cannot depend on that owner, accept the underlying primitive at that boundary and keep the stronger type in the owning layer.
- Prefer `frozen=True` on dataclasses where possible. Prefix internal fields with `_`.
- Put logic fully owned by a dataclass on the dataclass. If a value is completely determined by the instance's other fields, expose it as a property instead of passing or recomputing it at construction sites
- Use `MutableMapping` instead of `dict` for mutable dataclass fields.
- For function parameters, return types, and dataclass or Pydantic fields, use the widest read-only collection type that preserves the required invariants. Prefer `Sequence[T]` over `list[T]` or `tuple[T, ...]`, and `Mapping[K, V]` over `dict[K, V]`, when every permitted implementation is valid.
- A read-only interface does not guarantee an immutable value: `Sequence[T]` can be a mutable `list[T]`. Python has no general frozen-sequence type, so use `tuple[T, ...]` when ordered values must be immutable or hashable, including fields on frozen objects used as mapping or cache keys. Use `frozenset[T]` when unordered values must be immutable.
- Prefer idiomatic dict operations: `.get(key, default)` over if/else lookups, `.pop()` over `del`.
- Don't manually splice batch results into input order with `iter()` and `next()`. Track input indices and pair results with `zip(..., strict=True)` 
- When re-raising exceptions, use `raise e1 from e2` to preserve the original cause.
- In projects that use UV, run `uv lock` after adding, removing, or changing a dependency and include the regenerated `uv.lock` in the same change.
- Branch on enum values with `match`, not ternary expressions or `if`/`elif` chains, and handle every enum member explicitly.
- Every `match` statement must end with `case _ as unreachable: assert_never(unreachable)` on the matched value. This adds exhaustive matching
- Keep internal-package `__init__.py` files empty. Re-export names from `__init__.py` only when the package intentionally defines a public-facing library API.
- For Linux subprocess memory replays, read `VmRSS` and `VmHWM` from `/proc/self/status` inside the child. `resource.getrusage(RUSAGE_SELF).ru_maxrss` can carry a parent's earlier high-water mark across `fork`/`exec`; report the greater of `VmHWM` and sampled `VmRSS` as the observed peak, since the high-water reading can lag a sample.
