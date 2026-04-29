---
applies_to: Any project when writing or reviewing tests
skip_if: Not writing or reviewing tests
---

# Testing: Avoid Implementation Details

Tests should verify observable behavior — what the end user sees, clicks, or receives — not how the code internally achieves it.

- Assert on outputs, rendered content, and user-visible side effects. Do not assert on internal state, private method calls, or intermediate data structures.
- Never call or test private symbols directly. In Python, `_`-prefixed names are private — do not import them in tests. The same rule applies in every language (TS/JS `#` or convention-private, C++ `private:`, etc.): go through the public API. If a behavior is only reachable via a private symbol, either the public API is missing a seam or the behavior is an implementation detail that shouldn't be tested directly.
- When testing values that are semantically unordered (e.g. URL query strings, sets, object keys), do not assert on a specific ordering. Parse the value into a structure where order is irrelevant and compare that instead.

  ```typescript
  expect(Object.fromEntries(new URL(url).searchParams)).toEqual({
    id: "test_id",
    start_date: "2025-01-01",
    end_date: "2025-01-31",
  });
  ```

- Prefer interacting with components the way a user would (by visible text, labels, roles) over selecting by class names, test IDs, or internal component hierarchy.
- If a refactor that preserves behavior causes a test to fail, the test was testing implementation details.

