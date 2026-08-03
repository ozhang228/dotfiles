---
applies_to: C++ projects (*.cpp, *.h, *.hpp)
skip_if: Working in TypeScript, Python, or any non-C++ language
---

# C++

- Always mark meaningful return values as `[[nodiscard]]`.
- Use domain enums and tiny types instead of vendor enums or raw scalars when values have distinct meanings. Convert to third-party types at the integration boundary.
- Make failure types match the operation: return `outcome::result<T, E>` for all-or-nothing work, and expose per-item results only when partial success is intentional and usable.
- Keep absence explicit until an integration boundary. If an upstream API requires a sentinel such as a default-constructed date, isolate that conversion and make the sentinel contract clear.
- Let an abstraction retain the resources it owns. Do not keep a second lifetime-only handle when the fiber, executor, or similar object already owns the dependency; inline one-use default arguments that add no domain meaning.
- Centralize lazy Python C API initialization. Propagate initialization exceptions, and reserve a caster's `false` return for an ordinary type mismatch rather than swallowing setup failures.
- When asserting on `std::expected` in tests, pipe the error into the assertion so failures are readable:
  ```cpp
  ASSERT_TRUE(result.has_value()) << result.error();
  ```
