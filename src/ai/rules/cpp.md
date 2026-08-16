---
applies_to: C++ projects (*.cpp, *.h, *.hpp)
skip_if: Working in TypeScript, Python, or any non-C++ language
---

# C++

- Always mark meaningful return values as `[[nodiscard]]`.
- In domain models, use domain enums and tiny types instead of vendor enums or raw primitives when the field name supplies meaning that the type does not, such as price, vol, rate, amount, quantity, ID, convention, loading, YTE, or strike. Search for and reuse the canonical domain type first. Preserve the type inside `optional`, `vector`, `variant`, and result types. A Python binding is still a domain boundary: use transparent casters there instead of weakening the C++ model. Keep primitives for local arithmetic, indices/counts, flags, error or serialized payloads, and exact third-party calls; unwrap tiny values only at that boundary. Use an enum, not a tiny string, for a closed set of values.
- Make failure types match the operation: return `outcome::result<T, E>` for all-or-nothing work, and expose per-item results only when partial success is intentional and usable.
- Keep absence explicit until an integration boundary. If an upstream API requires a sentinel such as a default-constructed date, isolate that conversion and make the sentinel contract clear.
- Let an abstraction retain the resources it owns. Do not keep a second lifetime-only handle when the fiber, executor, or similar object already owns the dependency; inline one-use default arguments that add no domain meaning.
- Centralize lazy Python C API initialization. Propagate initialization exceptions, and reserve a caster's `false` return for an ordinary type mismatch rather than swallowing setup failures.
- Treat successful `PyDateTime_IMPORT` as a hard precondition for every `PyDate_*` and `PyDateTime_*` C API macro. Check `PyDateTimeAPI` after import and propagate failure before calling any datetime API; accessing those macros with a null API pointer is undefined behavior.
- When asserting on `std::expected` in tests, pipe the error into the assertion so failures are readable:
