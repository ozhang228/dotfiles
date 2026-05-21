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
- **Avoid tautological tests.** If the test re-implements the same logic as the code under test, it doesn't catch regressions — flipping a sign in both places leaves the test green. Examples: writing `assert result == (a - b) / (c - d) * 0.25` to check a function that computes `(a - b) / (c - d) * 0.25`; manually computing a matrix's diagonal to compare against a function that also computes the diagonal. Instead, work the expected output by hand from the spec and **hardcode the literal** in the assertion: `assert np.isclose(result, 2.0)`, not `assert np.isclose(result, (12 - 10) / (0.5 - 0.25) * 0.25)`. The hand-computed constant is independent verification; the inline formula isn't.
- **Assert real values, not structural checks.** `assert data is not None` and `assert len(result) > 0` don't catch incorrect behavior — a broken implementation can still pass them. Assert specific expected values (with `np.isclose` for floats) or precise behavioral outcomes.
- **For UI/visual features, always include a worst-case test.** If every upstream call returns Err, what does the user see, and is it readable? The all-failure state often renders differently from partial-failure (e.g. plotly draws all-NaN cells transparent, so axis labels alone don't convey "errors happened here"). Designing for partial doesn't cover total. Applies to heatmaps, charts, tables, dropdowns, anything with a visible empty/partial/full spectrum.
- **Name happy-path tests after the function/mode under test, not the scenario.** Prefer `test_normalize_roll` and `test_normalize_fly` over `test_normalize_roll_uses_per_product_ytes` and `test_normalize_fly_linear_term_structure_is_zero`. Composed scenario names overload one test with a claim ("this proves X uses Y") and tempt you to write the assertion in terms of that claim — which often becomes the formula-recomputation tautology above. Reserve scenario-style names for tests that cover genuinely distinct behavior from the happy path (e.g. `_filters_serials`, `_handles_empty_input`, `_returns_unchanged_for_none_mode`).

## Example

```
test_parse_returns_empty_dict_for_blank_input
  why: blank input is the most common edge case from upstream callers; silent failure here masks bugs

test_parse_raises_on_unknown_keys
  why: forward compatibility is intentional, not accidental; locks in fail-fast behavior
```
