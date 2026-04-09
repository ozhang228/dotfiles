---
applies_to: Any project when writing or reviewing tests
skip_if: Not writing or reviewing tests
---

# Testing: Avoid Implementation Details

Tests should verify observable behavior — what the end user sees, clicks, or receives — not how the code internally achieves it. A test coupled to implementation details breaks when you refactor, even if the behavior is unchanged.

- Assert on outputs, rendered content, and user-visible side effects. Do not assert on internal state, private method calls, or intermediate data structures.
- When testing values that are semantically unordered (e.g. URL query strings, sets, object keys), do not assert on a specific ordering. Parse the value into a structure where order is irrelevant and compare that instead.

  ```typescript
  // Good — match the URL path, then assert on parsed params (order-independent).
  registerGetHandler(new RegExp(`^${BASE_URL}/resource`), (url) => {
    expect(Object.fromEntries(new URL(url).searchParams)).toEqual({
      id: 'test_id',
      start_date: '2025-01-01',
      end_date: '2025-01-31',
    });
    return Promise.resolve(Response.json(data));
  });

  // Bad — asserting on the exact URL string; breaks if param order changes.
  expect(fetchedUrl).toBe(`${BASE_URL}/resource?id=test_id&start_date=2025-01-01&end_date=2025-01-31`);
  ```

- Prefer interacting with components the way a user would (by visible text, labels, roles) over selecting by class names, test IDs, or internal component hierarchy.
- If a refactor that preserves behavior causes a test to fail, the test was testing implementation details.
