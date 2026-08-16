---
name: typescript-review
description: TypeScript/React code review standards for desk-tools frontend. Load for code review whenever the PR touches TypeScript or TSX. Covers component architecture, testing strategy, type safety, and code organization. Distilled from real reviewer comments by kosterbauer and polson.
---

# TypeScript Review

Use this alongside the `code-review` skill for any TypeScript/React PR.

Evidence refresh: the latest 50 `TypeScript`-labeled desk-tools PRs created from 2026-07-09 through 2026-08-07 contained 51 comments that kosterbauer or polson left while reviewing another author's PR, across 12 PRs. Recurring comments support review heuristics. A one-off preference remains a question unless the repository's rules or nearby code confirm it.

---

## Start with the smallest semantic diff

First identify the exact behavior or contract that must change. Then challenge every extra type, helper, state field, and refactor against that behavior.

Recurring review questions include:

- Could a direct schema or type change express the new contract?
- Does this hunk change behavior at all?
- Is the same concept represented in two places?
- Did a feature PR absorb a rename, cleanup, or abstraction it does not need?

Do not suggest a denser rewrite just to remove lines. Split long expressions into named intermediate values when that makes the domain steps easier to inspect.

Representative comments:

> "I was imagining just changing hide from `z.boolean().optional()` to `z.boolean()`. What's the advantage of doing it this way?" (polson, PR #3585)

> "Why is this here? It doesn't change the behavior at all, right?" (polson, PR #3490)

> "This is quite a mouthful, can you split it out into more vars?" (polson, PR #3585)

---

## Trace contract changes across every reader and writer

When a PR changes serialized state, a parser, or an API contract, enumerate all sibling clients and all read/write paths before reviewing the implementation details. A correct custom-view migration is still incomplete if the main-view client owns the same contract.

This is a search obligation, not a demand to broaden unrelated UI behavior. Only change siblings that share the affected contract.

> "Shouldn't you also make this change to mainRiskViewerClient?" (polson, PR #3585)

---

## Preserve useful type information

- Keep nominal types and discriminants unless the PR proves they no longer encode an invariant.
- Handle discriminated unions with a `switch` and an exhaustive check. Review every variant's behavior independently.
- Use `unknown` when a generic value is intentionally opaque. Do not invent a fake concrete type or cast past the gap.
- Question casts and `satisfies` when inference or a better boundary type can express the same fact.
- Keep parser schemas private when callers only need the parsed domain value. Exporting a Zod schema exposes an implementation detail and creates a second API.

Representative comments:

> "Please make switch + exhaustive check" and "Can we make this a switch with cases for string/number/etc?" (polson, PR #3490)

> "why are we removing the nominal type?" (polson, PR #3490)

> "If we don't care about the value of `T`, make it `Column<unknown>`" (polson, PR #3490)

> "nit: why export zod schema? its an implementation detail of the parser" (kosterbauer, PR #3397)

---

## Keep parsing and transport details at the boundary

Parse external input once and expose an internal type that makes downstream states explicit. Do not keep wire-format strings, server-key conventions, or network-stub mechanics flowing through React code.

Be precise about which side owns the payload. Validation for genuinely external data is required. Defensive checks against a payload this codebase itself constructs need a concrete failure mode, not a generic "malformed server data" rationale.

Comments for temporary workarounds should name what triggers them and what evidence would prove they can be removed.

---

## React ownership and effects

- Keep display/rendering concerns separate from connection, parsing, and transport concerns.
- Treat an effect that coordinates several unrelated responsibilities as a refactoring signal. Prefer directly derived state and narrow event handlers.
- Prefer React's stricter event/effect APIs over mutable refs when they express the lifecycle correctly, but verify the actual synchronization need first.

> "this more closely intertwines the display/rendering layer (react) with the data/parsing layer" (kosterbauer, PR #3394)

> "agreed that there is too much going on in this effect and it needs a refactor" (kosterbauer, PR #3394)

Do not turn an architectural preference into a blocking comment without checking the system-level cost. In PR #3394, kosterbauer accepted multiple direct connections after the author explained that a proxy service would add more operational complexity while the UI remained the only client.

---

## Module-level functions: no arrow functions

> "All of the module-level functions you define in this PR should not be arrow-functions" (kosterbauer, referencing the DAT Developer style guide)

Module-level named functions should use `function` declarations, not arrow-function assignments. Arrow functions are fine for callbacks, inline handlers, and component props.

Style guide reference: https://wiki.drwholdings.com/spaces/FIO/pages/495308909/DAT+Developer#DATDeveloper-TypeScript%2FReact

---

## Type guards: avoid unless necessary

> "We don't have clear convention on typeguards yet, but I dislike them and think they can be avoided in 99% of time at the cost of slightly more verbose code. Can we write this without the typeguard? If not, I'd like to understand why" (kosterbauer)

Before adding a type guard, ask if slightly more verbose code would eliminate the need. If a type guard is genuinely required, explain why in the PR.

---

## Testing: integration over unit for components

> "I'd generally find tests that integrate subcomponents with the primary use-case more useful than unit tests on the subcomponent in a way that isn't necessarily 1:1 with how it will get used. In this case I'd prefer more of these tests live in the RiskViewerTable.test.tsx component where the RiskViewerTable component actually defines the autoGroup column def and installs it on the production grid rather than in a instrumentFilter.test.tsx that uses a render helper which doesn't necessarily correspond to how the thing that is deployed/care to catch regressions on is using it" (kosterbauer)

For component tests: prefer integration tests from the parent that owns the real use-case over unit tests on a subcomponent that rely on a test render helper not used in production.

For UI flows that cross the network boundary, prefer a small application fake plus user-visible assertions. Transport interception is acceptable when no fake exists, but the test should still drive the real user interaction. Keep assertions and network mechanics inside a named helper so the test reads as user action followed by observable result.

> "how the server behaves/how it responds to requests is really not the concern of what is under test is in the UI layer. The goal is to test user facing behavior" (kosterbauer, PR #3397)

> "I think a higher-level test where the user interacts with the grid and does some edit -> payload that is sent is intercepted and validated" (kosterbauer, PR #3397)

---

## Testing: grid display layer needs coverage

> "Would like at least one test on the grid display layer" (kosterbauer)

Any PR that changes ag-grid rendering, column defs, or row display should include at least one test that exercises the grid display layer, not just the data transformer.

---

## Testing: understand why async helpers appear

> "As discussed I'd like to know _why_ we suddenly need async helpers to get our tests to pass. Running theory is suspense changes and perhaps ag-grid uses suspense?" (kosterbauer)

Don't add `waitFor` / `act` / async test helpers without understanding why they're needed. If they appear in a PR as a fix for flaky tests, the root cause should be stated in the PR description.

Set stubs and expected server behavior before rendering when the component can issue requests during mount. Prefer repository assertion helpers such as `toBeChecked` when they provide better failure messages than a generic property assertion.

---

## Testing: keep causal inputs local

Construct the fixture in the test body, not a module-level constant, so the input-to-output relationship is visible without jumping to a non-local variable.

> "test data should be randomly generated with a util function that allows passing in overrides -- this prevents implicit reliance in tests on hard-coded data" (kosterbauer, PR #3397)

> "avoid constants at the module level, so I don't have to go to a non-local variable to evaluate if the test input -> test output is sound" (kosterbauer, PR #3397)

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

## Shared protocol utilities: recognize real recurrence

> "Serialization of ag-grid state is going to be a problem that repeatedly comes up and it would be great to not have to solve it a bunch of times" (kosterbauer)

State serialization, URL persistence, filter encoding, and application fakes are protocol boundaries that often recur across components. Give the shared contract one narrow owner once recurrence is concrete or inherent to the protocol. Do not pre-build a broad fluent framework for hypothetical callers.

The same boundary applies to test helpers. Centralize ag-grid interactions that must mimic production behavior, but keep the API close to how a test author thinks about the visible grid. Avoid long promise-returning method chains whose composition looks cleaner than its actual async use.

---

## Code organization

> "I think this can live in lib/dash/component" (kosterbauer)

New shared components and utilities should go in the appropriate shared lib directory, not be co-located in a feature directory where they'll drift or get duplicated.

New projects must be added to `pnpm-workspace.yaml` and the root `Makefile`.

Prefer a function returning a plain object over a class when there is no identity, inheritance, shared-prototype, or measured allocation need. Treat this as a preference to investigate rather than a blanket ban on classes.

> "I'd mildly prefer a function that returns a JS object over a class ... so long as we don't need to make e.g. memory optimizations for objects that will be instantiated millions of times" (kosterbauer, PR #3394)

---

## Accessibility: essential information needs a focusable path

Do not rely on a native `title` attribute for essential instructions. Keyboard and screen-reader behavior varies by browser and operating system. Use the project's standard tooltip when supplementary hover/focus help is appropriate, and keep essential meaning in visible text or an accessible label.

This was explicitly non-blocking in PR #3504 because the desk-tools user and browser context may reduce the impact. Verify the actual Tone component behavior before filing it as a bug.

---

## Backend/frontend coordination: ship together when possible

> "Why not roll the back and frontend changes together so we don't have to worry about compatibility/coordinating release? (and we can see the feature end-to-end for review)" (kosterbauer)

When a feature requires both backend and frontend changes, prefer shipping them in the same PR or a tightly coordinated pair. Separately shipped halves mean reviewers can't verify end-to-end behavior and introduce a window where the two halves are mismatched.

---

## PR scope: one concern per PR

> "In the future, please split up complex PRs to be smaller. Let's also avoid bloat in unrelated changes (e.g. 'AxisSpace' -> 'CoordinateSpace' shouldn't have gone in this PR, probably)" (kosterbauer)

> "This PR is far too big. Please split it up. Maybe make the string filters a separate PR?" (polson, PR #3490)

Renames, reformatting, and "while I'm here" cleanups go in separate PRs. The diff for the actual feature should be scannable on its own.

---

## PR descriptions and screenshots

> "Could you add screenshots/recording to the PR description so the UX of the newly added filter is clear?" (kosterbauer)
> "Please fill out PR description" (kosterbauer)
> "Please add the JIRA and TODO before merging" (kosterbauer)

For any UI change: add a screenshot or screen recording to the PR description. Reviewers can't run the frontend locally for every PR.
