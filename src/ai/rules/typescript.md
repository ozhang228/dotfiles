---
applies_to: TypeScript and React projects (*.ts, *.tsx)
skip_if: Working in Python, C++, or any non-TypeScript/JavaScript language
---

# TypeScript

- No anonymous functions at module level.
- Functions with more than two parameters of a shared type must take a single options object instead.
- Follow Google's TypeScript style guide.
- No default exports.
- Prefer pure, framework-agnostic functions over hooks. Minimize hook logic; extract testable helpers.
- Destructure props in React component signatures.
- Self-close React components that have no children.
- Use destructured arguments rather than patterns like `args: {}`.
- Prefer `undefined` over `null`. Convert `null` from browser/library APIs to `undefined` at the boundary.
- Prefer default parameter values over nullish coalescing (`??`) when possible.
- Never use type assertions (`as`, `var!`). Maintain type safety. Use `checkExists` instead.
- Always annotate caught errors as `unknown` and assert them through a helper (e.g. `assertIsError`).
- Be intentional with optional properties:
  - `{ lines?: ConstructedLine[] }` — the key may be omitted.
  - `{ lines: ConstructedLine[] | undefined }` — the key must exist, but may be `undefined`.
  - Choose the form that matches your intent.

## React State

- Don't sync state with `useEffect`. If a child's state change needs to affect a sibling or parent, hoist the state up to their common ancestor instead of reading it back down through an effect. Reserve `useEffect` for synchronizing with something truly external (a subscription, a DOM API, a non-React library) — not for keeping two pieces of your own component tree in sync.
- Don't call `setState` inside a loop. Compute the final value first, then call `setState` once — either by reducing outside the call, or by doing the loop inside a single functional updater (`setState(prev => ...)`). Looped `setState` calls can trigger a re-render per iteration and are hard to follow regardless.
- If you notice a single user action driving more than two or three state variables through a chain of effects and handlers, that's a sign the state is split across too many places — look for a way to collapse it into fewer, more directly-derived pieces of state before adding another effect to the chain.

## Testing

- Hoist variables relevant to why a test passes or fails into the test itself, not shared state.
- Test stub generators must populate all fields with random data by default. The caller passes in only the fields that matter.

  ```typescript
  function buildOrder(overrides: Partial<Order> = {}): Order {
    return {
      id: crypto.randomUUID(),
      customer: `customer-${Math.random().toString(36).slice(2)}`,
      total: Math.random() * 1000,
      status: "pending",
      ...overrides,
    };
  }
  ```

- See `general.md`'s "Recurring bad-test patterns" for the cross-language test-quality checklist, including hardcoding expected values instead of computing them with the same logic under test (tautological-by-construction).

