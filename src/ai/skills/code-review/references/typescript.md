---
name: typescript-review
description: TypeScript and React code review rules covering contracts, type safety, component ownership, testing, and scope.
---

# TypeScript Review

Use alongside the `code-review` skill for TypeScript and React changes. Apply repository rules before general preferences.

## Start with the smallest semantic diff

- Identify the exact behavior or contract that must change, then justify each extra type, helper, state field, and refactor against it.
- Prefer a direct schema or type change when it expresses the contract.
- Give duplicated concepts one owner.
- Keep incidental renames, cleanup, and abstractions out of a feature change.
- Split long expressions into meaningful intermediate values when that makes the domain steps easier to inspect.
- Do not suggest denser rewrites solely to remove lines.

## Trace every reader and writer

- When serialized state, a parser, or an API changes, find all clients and read/write paths that share the affected contract.
- Update affected siblings without broadening unrelated UI behavior.

## Preserve type information

- Keep nominal types and discriminants unless the change proves they no longer encode an invariant.
- Handle discriminated unions with a switch and an exhaustive check; inspect every variant's behavior.
- Use `unknown` when a generic value is intentionally opaque.
- Prefer inference or a stronger boundary type over casts that bypass validation.
- Keep parser schemas private when callers only need parsed domain values.
- Prefer discriminated unions and ordinary narrowing over a new type guard when they express the same facts; keep necessary type guards at genuine boundaries.

## Parse at the boundary

- Parse external input once and expose a precise internal type.
- Keep wire formats, server-key conventions, and network-stub mechanics out of React components.
- Validate genuinely external data. Additional defensive checks for code-owned payloads need a concrete runtime failure mode.
- For temporary workarounds, document the trigger and evidence needed to remove them.

## React ownership and effects

- Separate display and rendering from connection, parsing, and transport concerns.
- Prefer derived values and narrow event handlers when an effect coordinates unrelated responsibilities.
- Verify the synchronization need before replacing refs with another lifecycle API.
- Evaluate architecture changes against their operational cost; do not add a proxy or shared service solely to satisfy a layering preference.
- Use function declarations for named module-level functions. Arrow functions remain appropriate for callbacks, inline handlers, and component props.

## Test the user-visible behavior

- Test a component through the parent that owns the real use case when an isolated render helper bypasses production configuration.
- For network interactions, use a small application fake when one exists. Otherwise intercept transport while still driving realistic user interaction and asserting its visible result.
- Keep network mechanics and repeated UI interactions inside named helpers.
- Rendering changes need verification through the display layer; a data-transformer test alone does not establish the displayed result.
- Investigate why asynchronous test helpers are necessary rather than adding waits to hide unexplained failures.
- Configure stubs before rendering components that can request data during mount.
- Prefer accessible, semantic assertions with useful failure messages.
- Keep causal inputs and expected values in the test body. Shared builders may provide unrelated defaults, but must not hide load-bearing values.
- Use the project's canonical timestamp representations, making epoch units explicit. Do not silently mix seconds, milliseconds, and nanoseconds.
- Document screenshot-test setup and the snapshot update workflow when adding visual tests.
- Match existing page-object naming and describe visible components or actions.

## Share real protocols

- Give recurring serialization, URL persistence, filter encoding, and application-fake contracts one narrow owner.
- Avoid broad frameworks for hypothetical callers.
- Centralize interactions that must mimic the production UI while keeping the helper API close to user actions.
- Avoid long asynchronous method chains whose composition hides execution order.

## Code organization

- Put shared components and utilities under their conceptual owner; keep feature-only code with its feature.
- Register new packages in the repository's workspace and build configuration when required.
- Prefer a function returning a plain object when a class has no identity, inheritance, shared-prototype, or measured allocation need.

## Accessibility

- Give essential information a visible or accessible path; do not rely solely on a native title attribute.
- Use the project's standard tooltip for supplementary hover and focus help.
- Verify the actual component, browser, and keyboard behavior before reporting an accessibility bug.

## Coordinate releases and review

- Review backend and frontend changes together, or document compatibility and ordering for a coordinated pair.
- Keep each PR focused on one concern and explain any necessary downstream migration.
- Describe the concrete behavior change and validation. Include a screenshot or recording when it helps reviewers assess a UI change.
