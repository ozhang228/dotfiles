# Testing — Behavior Specification

Use this during brainstorm to define the expected behaviors of the feature before implementation begins. These become the test plan.

For the test-quality bar itself (tautological tests, vacuous assertions, brittle-to-refactor tests, and the rest), see `general.md`'s "Recurring bad-test patterns" — that list is canonical and applies here unchanged. See also general.md's "Tests as documentation": the `what`/`why` format below exists specifically so the behavior list doubles as documentation of the feature, readable without opening any code. This file only covers what's specific to defining behaviors *before* the code exists.

## Format

A flat list, one entry per behavior:

```
test_<descriptive_name>
  what: <the exact scenario — inputs and the specific expected observable outcome>
  why: <one sentence on what regression this protects against and why it matters>
```

`what` and `why` answer different questions — don't let one collapse into the other. `what` must commit to a concrete, checkable outcome (a value, a state transition, a rendered result), not a restatement of the behavior's name. If you can't write a concrete `what`, the test isn't ready to define yet — the design underneath it is still vague. `why` is the justification a reviewer needs to judge whether the test is worth keeping; it should read as a reason, not a second description.

## Rules

- One test per behavior. If `why` reads "covers X and also Y", split it.
- Skip things that only assert framework behavior, trivial getters, or type-checker output.
- Skip duplicate coverage — see general.md's "Redundant test coverage".
- Order from happy path to edge cases.
- Describe observable behavior — what the user sees, receives, or what the public API returns — not how the code achieves it.
- **Don't test private functions.** If a function is worth testing, make it public first. A `_name` function being tested in isolation is a design smell, not a test.
- **For UI/visual features, always include a worst-case test.** If every upstream call returns Err, what does the user see, and is it readable? The all-failure state often renders differently from partial-failure (e.g. plotly draws all-NaN cells transparent, so axis labels alone don't convey "errors happened here"). Designing for partial doesn't cover total. Applies to heatmaps, charts, tables, dropdowns, anything with a visible empty/partial/full spectrum.
- **Name happy-path tests after the function/mode under test, not the scenario.** Prefer `test_normalize_roll` and `test_normalize_fly` over `test_normalize_roll_uses_per_product_ytes` and `test_normalize_fly_linear_term_structure_is_zero`. Composed scenario names overload one test with a claim ("this proves X uses Y") and tempt you to write the assertion in terms of that claim — which often becomes the formula-recomputation tautology general.md warns about. Reserve scenario-style names for tests that cover genuinely distinct behavior from the happy path (e.g. `_filters_serials`, `_handles_empty_input`, `_returns_unchanged_for_none_mode`). The name plus `what` together should let someone skimming the list tell exactly what's being tested without opening the test file.
- **Re-run the general.md checklist when the assertion is actually written, not just now.** A `what`/`why` pair approved at design time can still turn tautological or vacuous once real code gets written during TDD — the failure mode general.md describes happens at the assertion, not at the plan. Treat this list as re-checked, not one-and-done.

## Example

```
test_parse_returns_empty_dict_for_blank_input
  what: parse("") returns {} rather than raising or returning None
  why: blank input is the most common edge case from upstream callers; silent failure here masks bugs

test_parse_raises_on_unknown_keys
  what: parse('{"bogus_key": 1}') raises UnknownKeyError naming "bogus_key"
  why: forward compatibility is intentional, not accidental; locks in fail-fast behavior
```
