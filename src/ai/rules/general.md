---
applies_to: All languages and projects
skip_if: Never — this always applies
---

# General

## Naming

- A name should say what a thing *is* or *does*, not how it's currently implemented or where it came from. Reject names that borrow jargon from one system to describe a concept in another (e.g. naming a general provider after a specific upstream dependency it happens to call today).
- If a name undersells fallible behavior (e.g. `query`, `get`, `fetch` for something that can raise or return an error), prefer a name that signals it, or route it through the project's established fallible-call convention.
- When picking between two reasonable names, prefer the one a new reader could guess the behavior of without opening the file.

## Splitting one branch into multiple PRs

When a plan splits a large diff into sequential PRs by file scope (e.g. "PR2 gets these whole files, PR3 gets the rest"), staging exactly the planned files is not enough validation. A type/name change in an early PR (e.g. renaming a class into a union member) can break files nominally scoped to a *later* PR — they still reference the old name, or access a now-narrower attribute without a match/isinstance guard — but this won't show up if the later PR's files sit unstaged in the same working tree, since the test runner and type checker read files off disk regardless of git staging.

Before committing an earlier PR in the split, isolate its exact tree:

```
git stash push --keep-index -u -m "later-PR leftovers"   # stash everything NOT staged
<test suite>                                              # full suite against staged-only tree
<type checker>                                             # diff error count against the base branch's baseline
git stash pop                                              # restore the rest of the split
```

If this surfaces a break in a "later PR" file, the fix (usually a rename or a narrowing `match`) belongs in the *earlier* PR, since that PR must leave the tree green standalone — don't defer it just because the plan said that file belongs later.

## Benchmarking

Benchmark the full production call path (real clients, real config, real data volume), not an isolated function in a microbenchmark. Only drill into a subfunction once the end-to-end run has identified it as the actual hotspot — an isolated benchmark can look damning while being irrelevant to real throughput.

## Edit-tool boundary hazard

When an edit inserts a new class/function next to an existing one, an `old_string` that stops mid-body can silently reassign the existing definition's trailing methods to the new class. This is type-valid, so `tsc`/`ty`/linters won't catch it — only the actual test suite will. Re-read the full boundary (start of the next sibling definition, not just up to a plausible-looking cut point) before trusting an edit near existing code.

## One linter isn't the gate

Validating a lint/typing workaround against a single tool (e.g. `ty` alone) gives false confidence when the real CI gate runs multiple tools (e.g. ruff + ty, or eslint + tsc). Always run the full check suite the project actually gates on before declaring something clean.

## Squash onto merge-base, not main

When squashing a branch cut from an older base, `reset --soft` to the actual merge-base (`git merge-base HEAD main`), not current `main`/`master`. Resetting to current main makes the PR diff show a phantom revert of everything main gained since the branch was cut.

## Grep the whole app for copy-pasted bug patterns

On finding a bug caused by a copy-pasted pattern, grep the whole codebase for the same pattern immediately rather than fixing only the file that appeared in the traceback or bug report. Copy-paste bugs rarely occur exactly once.

## Verify every file in a bulk deletion

Don't approve or execute a bulk deletion based on a partial or sampled scan of the file list. Verify each file individually meets the deletion criteria before acting — a bulk operation is often irreversible.

## Read the full condition on version/flag gates

When auditing version-gated or flag-gated code (e.g. `sys.version_info == (3, 9)` vs `>= (3, 11)`), read the entire boolean condition rather than pattern-matching on the version/flag name. The comparison operator and direction change the meaning as much as the value does.

## Tests as documentation

For most features, a test suite's secondary job is documentation: someone unfamiliar with the code should be able to learn what a function does and doesn't guarantee by reading test names and bodies alone, without opening the implementation. That means naming and structuring each test around one specific, observable behavior, and writing the assertion so the expected outcome is legible on its own (a pinned literal, not an expression the reader has to evaluate). If you can't tell what behavior broke from a failing test's name and body without reading the code under test, the test isn't pinning down behavior, it's just exercising code — rewrite it. This is also why the patterns below matter beyond "might miss a bug": a tautological or vacuous test doesn't just fail to catch regressions, it actively misdocuments the behavior as verified when it isn't.

## Recurring bad-test patterns

These apply in any language — the failure is in the test's *logic*, not a language-specific idiom.

- **Trivial no-op test:** testing a function whose entire body is a stub (`raise NotImplementedError(...)`, `TODO`, a bare pass-through). There's no logic to verify, only the literal you just wrote — delete the function or delete the test, don't write a test that re-asserts the stub.
- **Trivial-by-default test:** an argument passed into the constructor/helper under test happens to equal that helper's own default value, so the assertion holds whether or not the code path being tested is real. Caught example: a Python test called `_skew(rate_floor=0.026)` where the builder's own default `rate_floor` was already `0.026` — the assertion passed identically whether the property under test actually read `self.rate_floor` or returned a hardcoded `0.026` literal. Fix: pick an input value that differs from every default in the builder/fixture, so the assertion can only hold if the real wiring executed. If a value coincidentally matches a default, change it — don't accept the coincidence.
- **Tautological-by-construction test:** the "expected" value is derived by calling the same function (or its exact inverse) under test, rather than an independently known number or reference. Round-trip tests (`f(g(x)) == x`) are the classic case — a consistent bug present in both directions (e.g. a sign flip in both a forward and inverse conversion) cancels out and the round trip still passes. One codebase hit exactly this class of bug (an SD sign-convention error) and then reintroduced a round-trip-only test in the same file later. Fix: pin the *intermediate* value too, with a literal computed once and reviewed, in addition to (not instead of) the round-trip check.
- **Vacuous success-shape test:** asserting only that a call succeeded (`isinstance(result, Ok)`, `assert response.status == 200`, `np.isfinite(x)`, `assert result`, `assert len(result)`, `assert result is not None`) when the function has a real, computable expected value. Any wrong-but-successfully-shaped output satisfies these. Replace with the actual pinned value (`assert result == expected_value`) once you know what correct looks like — reserve success/error-shape assertions for cases where no single correct value exists (e.g., "this must error, but any error message is acceptable").
- **Unverified-assumption test name:** naming a test after an assumption about the system that was never checked against real data. Caught example: a test named `..._uses_libor_fixing_path` when the model's real `FundingIndex` was `USD-SOFR`, not LIBOR — nobody grepped the fixture before naming it. Before finalizing a test name, check the real data (fixture, config, prod state) the test exercises to confirm the name's claim is actually true, not just plausible.
- **Unverified secondary input:** when a test isolates one input to prove behavior is independent of it (e.g. "vol is normal regardless of beta"), the *other* inputs in the setup must be load-bearing, not decorative. Run the test with a default/simplified value for each supporting input and confirm it actually fails — if it still passes, that input isn't proving anything and should either be justified or removed. A "regardless of X" test with an unverified secondary input can pass by construction rather than by the invariant it claims to check.
- **Redundant test coverage:** two tests that would fail for the same reason test nothing extra — they add maintenance cost, not confidence. Before adding a test, check whether an existing test already fails for the same root cause; if so, keep the better-named one and drop the other.
- **Brittle-to-refactor test:** asserting on implementation details (mock call counts, private/internal state, exact intermediate data structures) instead of observable output makes a test fail on a harmless refactor even though behavior didn't change. A test should only break when the public, observable contract changes — not when you rename a helper, reorder internal calls, or swap an internal data structure that isn't part of the return value.
- **Untestable-by-construction test:** before trusting a test, check whether it can actually fail given the available stubs/fixtures. If a stub returns identical data across the branches a test is meant to distinguish, any assertion comparing them is trivially green regardless of whether the code under test is correct. A test that cannot fail is worse than no test — it looks like coverage without being any.
