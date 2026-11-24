# Behavior Contracts and Verification

Use this during brainstorm to define what must be true before deciding how each behavior should be verified. The result is a behavior contract, not automatically a test plan.

For the test-quality bar itself (tautological tests, vacuous assertions, brittle-to-refactor tests, and the rest), see `~/dotfiles/src/ai/rules/testing.md`. Its "Tests as documentation" guidance is why the `what`/`why` format below doubles as readable feature documentation without opening any code.

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
- Describe observable behavior — what the user sees, receives, or what the public API returns — not how the code achieves it.
- Don't test private functions. If a function is worth testing, make it public first.
- Name happy-path tests after the function/mode under test, not the scenario. Prefer `test_normalize_roll` and `test_normalize_fly` over `test_normalize_roll_uses_per_product_ytes` and `test_normalize_fly_linear_term_structure_is_zero`. Composed scenario names overload one test with a claim ("this proves X uses Y") 

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
