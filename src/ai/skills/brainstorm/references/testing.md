# Behavior Contracts and Verification

Use this during brainstorm to define what must be true before deciding how each behavior should be verified. The result is a behavior contract, not automatically a test plan.

For the test-quality bar itself (tautological tests, vacuous assertions, brittle-to-refactor tests, and the rest), see `GLOBAL.md`'s "Recurring bad-test patterns" — that list is canonical and applies here unchanged. See also GLOBAL.md's "Tests as documentation": the `what`/`why` format below exists specifically so the behavior list doubles as documentation of the feature, readable without opening any code. This file only covers what's specific to defining behaviors *before* the code exists.

## Verification classes

- `test`: Write a new automated test because it uniquely exercises behavior worth pinning.
- `invariant`: Preserve the behavior in the design, but do not add a test. Use this when types, framework validation, existing coverage, or a stronger test already enforces it, or when the statement guides implementation without needing independent executable coverage.
- `manual check`: Verify through a running system, visual inspection, metrics, or another environment-dependent workflow that a unit test cannot represent honestly.

Classify before naming. Only `test` entries receive `test_...` names and enter the TDD implementation plan.

## Format

A flat list, one entry per behavior:

```
verification: test | invariant | manual check
name: <test name only for a test; otherwise a short behavior label>
  what: <the exact scenario — inputs and the specific expected observable outcome>
  why: <why the behavior matters and why this verification class is sufficient>
```

`what` and `why` answer different questions. `what` commits to a concrete outcome, even for an invariant. `why` justifies both the behavior and its verification class. If an invariant cannot name what already covers it or why automation adds no value, reconsider whether it needs a test.

## Rules

- One entry per behavior. If `why` reads "covers X and also Y", split it.
- Classify framework behavior, trivial getters, type-enforced wiring, and duplicate coverage as invariants or omit them. Do not create tests for them.
- A behavior can remain in the contract even when it should not become a test. This keeps design intent visible without manufacturing low-value coverage.
- Order from happy path to edge cases.
- Describe observable behavior — what the user sees, receives, or what the public API returns — not how the code achieves it.
- **Don't test private functions.** If a function is worth testing, make it public first. A `_name` function being tested in isolation is a design smell, not a test.
- **For UI/visual features, always include a worst-case test.** If every upstream call returns Err, what does the user see, and is it readable? The all-failure state often renders differently from partial-failure (e.g. plotly draws all-NaN cells transparent, so axis labels alone don't convey "errors happened here"). Designing for partial doesn't cover total. Applies to heatmaps, charts, tables, dropdowns, anything with a visible empty/partial/full spectrum.
- **Name happy-path tests after the function/mode under test, not the scenario.** Prefer `test_normalize_roll` and `test_normalize_fly` over `test_normalize_roll_uses_per_product_ytes` and `test_normalize_fly_linear_term_structure_is_zero`. Composed scenario names overload one test with a claim ("this proves X uses Y") and tempt you to write the assertion in terms of that claim — which often becomes the formula-recomputation tautology GLOBAL.md warns about. Reserve scenario-style names for tests that cover genuinely distinct behavior from the happy path (e.g. `_filters_serials`, `_handles_empty_input`, `_returns_unchanged_for_none_mode`). The name plus `what` together should let someone skimming the list tell exactly what's being tested without opening the test file.
- **Re-run the GLOBAL.md checklist when the assertion is actually written, not just now.** A `what`/`why` pair approved at design time can still turn tautological or vacuous once real code gets written during TDD — the failure mode GLOBAL.md describes happens at the assertion, not at the plan. Treat this list as re-checked, not one-and-done.

## Example

```
verification: test
name: test_parse_returns_empty_dict_for_blank_input
  what: parse("") returns {} rather than raising or returning None
  why: blank input is a common caller case and no existing validation covers the parser branch

verification: invariant
name: unknown configuration keys fail validation
  what: config parsing rejects unknown keys before application startup
  why: the shared strict Pydantic base already enforces this, so another app-level test would duplicate framework coverage
```
