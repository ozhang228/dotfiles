---
name: typescript-review
description: TypeScript/React code review standards for desk-tools frontend. Invoke alongside pr-review whenever the PR touches TypeScript or TSX. Covers component architecture, testing strategy, type safety, code organization, and a pre-submit checklist. Distilled from real reviewer comments by kosterbauer.
---

# TypeScript Review

Use this alongside the `pr-review` skill for any TypeScript/React PR. These are the patterns kosterbauer flags consistently.

---

## Module-level functions: no arrow functions

> "All of the module-level functions you define in this PR should not be arrow-functions" (kosterbauer, referencing the DAT Developer style guide)

Module-level named functions should use `function` declarations, not arrow-function assignments. Arrow functions are fine for callbacks, inline handlers, and component props.

Style guide reference: https://wiki.drwholdings.com/spaces/FIO/pages/495308909/DAT+Developer#DATDeveloper-TypeScript%2FReact

---

## Type guards — avoid unless necessary

> "We don't have clear convention on typeguards yet, but I dislike them and think they can be avoided in 99% of time at the cost of slightly more verbose code. Can we write this without the typeguard? If not, I'd like to understand why" (kosterbauer)

Before adding a type guard, ask if slightly more verbose code would eliminate the need. If a type guard is genuinely required, explain why in the PR.

---

## Testing: integration over unit for components

> "I'd generally find tests that integrate subcomponents with the primary use-case more useful than unit tests on the subcomponent in a way that isn't necessarily 1:1 with how it will get used. In this case I'd prefer more of these tests live in the RiskViewerTable.test.tsx component where the RiskViewerTable component actually defines the autoGroup column def and installs it on the production grid rather than in a instrumentFilter.test.tsx that uses a render helper which doesn't necessarily correspond to how the thing that is deployed/care to catch regressions on is using it" (kosterbauer)

For component tests: prefer integration tests from the parent that owns the real use-case over unit tests on a subcomponent that rely on a test render helper not used in production.

---

## Testing: grid display layer needs coverage

> "Would like at least one test on the grid display layer" (kosterbauer)

Any PR that changes ag-grid rendering, column defs, or row display should include at least one test that exercises the grid display layer, not just the data transformer.

---

## Testing: understand why async helpers appear

> "As discussed I'd like to know _why_ we suddenly need async helpers to get our tests to pass. Running theory is suspense changes and perhaps ag-grid uses suspense?" (kosterbauer)

Don't add `waitFor` / `act` / async test helpers without understanding why they're needed. If they appear in a PR as a fix for flaky tests, the root cause should be stated in the PR description.

---

## Testing: standardize time representation

> "This PR makes it clear that how we represent times in (at least) the tests needs to be tightened up. I see in our test suites: ISO date time strings, ns since epoch, seconds since epoch, ms since epoch. We should likely have at most two in our test suites and I lean towards date time strings (for readability) and ns since epoch (since that is what the app uses). So we should probably have some helper that takes a string, validates that it is ISO8601, and converts it to ns" (kosterbauer)

In tests, represent timestamps as either ISO8601 strings or ns-since-epoch. Don't mix. If a PR introduces a new time representation, flag it.

---

## Testing: document how to update screenshot tests

> "If it isn't already clear how to update the screenshot tests, please make it clear somewhere" (kosterbauer)

Visual/screenshot test setup and snapshot update workflow should be documented in the project README. Any PR adding Playwright screenshot tests should confirm the README covers this.

---

## Naming: page-object helpers need consistency

> "Only thing I'd consider to be blocking is the naming around 'cell'. Other than that, it'd be good to standardize naming for these page-object helpers (suffix with something or just name them after their respective components?)" (kosterbauer)

Test page-object helpers should follow a consistent naming convention within the project. When adding new ones, match the existing pattern or propose a standard in the PR.

---

## Serialization: design for reuse from the start

> "Serialization of ag-grid state is going to be a problem that repeatedly comes up and it would be great to not have to solve it a bunch of times" (kosterbauer)

Patterns that will be needed across components (state serialization, URL persistence, filter encoding) should be designed as shared utilities from the first instance, not solved inline and refactored later.

---

## Code organization

> "I think this can live in lib/dash/component" (kosterbauer)

New shared components and utilities should go in the appropriate shared lib directory, not be co-located in a feature directory where they'll drift or get duplicated.

New projects must be added to `pnpm-workspace.yaml` and the root `Makefile`.

---

## Backend/frontend coordination: ship together when possible

> "Why not roll the back and frontend changes together so we don't have to worry about compatibility/coordinating release? (and we can see the feature end-to-end for review)" (kosterbauer)

When a feature requires both backend and frontend changes, prefer shipping them in the same PR or a tightly coordinated pair. Separately shipped halves mean reviewers can't verify end-to-end behavior and introduce a window where the two halves are mismatched.

---

## PR scope: one concern per PR

> "In the future, please split up complex PRs to be smaller. Let's also avoid bloat in unrelated changes (e.g. 'AxisSpace' -> 'CoordinateSpace' shouldn't have gone in this PR, probably)" (kosterbauer)

Renames, renamings, reformatting, and "while I'm here" cleanups go in separate PRs. The diff for the actual feature should be scannable on its own.

---

## PR descriptions and screenshots

> "Could you add screenshots/recording to the PR description so the UX of the newly added filter is clear?" (kosterbauer)
> "Please fill out PR description" (kosterbauer)
> "Please add the JIRA and TODO before merging" (kosterbauer)

For any UI change: add a screenshot or screen recording to the PR description. Reviewers can't run the frontend locally for every PR.

---

## Pre-submit checklist

Before approving or submitting a TypeScript/React PR:

- [ ] Module-level functions use `function` declarations, not arrow functions
- [ ] No type guards that could be avoided with slightly more verbose code
- [ ] New components tested via integration test from the parent that owns the real use-case
- [ ] Grid display layer has at least one test if column defs or row rendering changed
- [ ] No unexplained `waitFor`/`act` additions — root cause stated if added
- [ ] Time values in tests are ISO8601 strings or ns-since-epoch, not mixed
- [ ] Shared utilities placed in `lib/dash/component` or equivalent, not in feature dirs
- [ ] New project added to `pnpm-workspace.yaml` and root `Makefile` if applicable
- [ ] Backend+frontend shipped together or explicitly coordinated if split
- [ ] PR is one concern — no piggybacked renames or reformatting
- [ ] Screenshots/recording in PR description for any UI change
- [ ] PR description and JIRA link filled out
- [ ] Screenshot test update workflow documented if Playwright tests added
