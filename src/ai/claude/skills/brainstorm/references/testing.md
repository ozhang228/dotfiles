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

## Example

```
test_parse_returns_empty_dict_for_blank_input
  why: blank input is the most common edge case from upstream callers; silent failure here masks bugs

test_parse_raises_on_unknown_keys
  why: forward compatibility is intentional, not accidental; locks in fail-fast behavior
```
