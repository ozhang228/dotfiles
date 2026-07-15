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
