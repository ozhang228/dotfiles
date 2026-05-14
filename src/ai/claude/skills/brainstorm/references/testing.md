# Testing — Behavior Specification

Use this during brainstorm to define the expected behaviors of the feature before implementation begins. These become the test plan.

## Format

A flat list, one entry per behavior:

```
test_<descriptive_name>
  why: <one sentence on what behavior this protects and why it matters>
```

## Rules

- One test per behavior. If `why` reads "covers X and also Y", split it.
- Skip things that only assert framework behavior, trivial getters, or type-checker output.
- Skip duplicate coverage. If two tests would fail for the same reason, keep one.
- Order from happy path to edge cases.
- Describe observable behavior — what the user sees, receives, or what the public API returns — not how the code achieves it.
- **Don't test private functions.** If a function is worth testing, make it public first. A `_name` function being tested in isolation is a design smell, not a test.
- **Check test infrastructure feasibility.** Before finalizing each test, ask: can this test actually fail given the available stubs? If stubs return the same data for start and end, any diff-based test is trivially 0 regardless of whether the implementation is correct. Broken tests that always pass are worse than no tests.
- **Avoid tautological tests.** If the test re-implements the same logic as the code under test (e.g. manually computing the diagonal trick to compare against the function that also computes the diagonal trick), it doesn't catch regressions. Assert against independent computation or hardcoded fixture values derived from a known-good run.
- **Assert real values, not structural checks.** `assert data is not None` and `assert len(result) > 0` don't catch incorrect behavior — a broken implementation can still pass them. Assert specific expected values (with `np.isclose` for floats) or precise behavioral outcomes.

## Example

```
test_parse_returns_empty_dict_for_blank_input
  why: blank input is the most common edge case from upstream callers; silent failure here masks bugs

test_parse_raises_on_unknown_keys
  why: forward compatibility is intentional, not accidental; locks in fail-fast behavior
```
