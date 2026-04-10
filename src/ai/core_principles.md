---
applies_to: All code in any language
skip_if: Never skip — these rules always apply
---

# Core Principles

- Prioritize:
  - Immutability: prefer values that do not change over time
  - Pure functions: prefer functions without side effects (easy to test + reason about)
  - Explicitness: prefer explicit behavior and data flow
    - Avoid implicit assumptions that require hidden or global context
    - Code should state what it depends on and what it is doing
  - Simplicity: prefer a simple solution over a complex one
  - Exhaustive pattern matching for compile-time checking of unhandled cases
  - Automated tests: prove correctness, document expected behavior, defend against regressions
  - Shutting down the program with an error over silently failing

- Avoid:
  - Unused code: do not introduce functions, variables, types, or exports that are not actively used. Linters cannot catch dead code that is exported, so be disciplined about removing what isn't needed.
  - Comments: code should be self-documenting
    - Only add comments if explicitly asked or to explain business context
    - If used, keep comments concise
  - Global state: in any language, avoid global/shared mutable state. Pass dependencies explicitly. In React, Context is almost always unnecessary unless a value is consumed by many components at a large depth of the component tree — default to props.
  - Tests relying on a live-system or the file system
  - String parsing

- Domain types should be purely data. They should not contain methods that transform them into presentation or application-specific formats (e.g. `to_heatmap`, `to_json_response`). The application layer that consumes domain types is responsible for those transformations.

- Before starting on any code changes, always outline a plan. Identify what needs to be changed, what files these changes are in, and how you will approach it.

# Team Coding Style

- Do not expose library/implementation types in public interfaces. Define your own abstractions and map to/from library types at the boundary.
- Magic numbers must be extracted into named constants or accompanied by a comment, unless their meaning is immediately obvious from context.

## Client-Side Persistent State (URL params, localStorage, cookies)

- Always include a `version` field in the serialized payload. These storage locations cannot be preemptively migrated — old values will exist in the wild indefinitely — so a version makes it possible to detect the schema and migrate at read time.
- Group all related state into a single stringified JSON object rather than spreading across many keys or params. One object is easier to parse with a runtime validator (e.g. Zod, Pydantic) and migrate atomically.

  ```typescript
  // Good — single versioned object, easy to validate and migrate.
  const state = JSON.stringify({ v: 1, filters: ['open'], sort: 'date' });
  searchParams.set('state', state);

  // Bad — no version, scattered across multiple params, hard to migrate.
  searchParams.set('filters', 'open');
  searchParams.set('sort', 'date');
  ```

## Ternary Operations

- Never use a negation in a ternary condition. Flip the branches instead.
- The condition should always read as the positive case: `condition ? whenTrue : whenFalse`, never `!condition ? ... : ...`. This also applies to `!==` vs `==`.

  ```typescript
  // Good
  isEnabled ? handleEnabled() : handleDisabled();

  // Bad — negated condition; flip the branches instead.
  !isEnabled ? handleDisabled() : handleEnabled();
  ```
