---
applies_to: TypeScript and React projects (*.ts, *.tsx)
skip_if: Working in Python, C++, or any non-TypeScript/JavaScript language
---

# TypeScript

- Hard-pin every dependency version in `package.json` (exact version, no `^` or `~` range).
- Prefer `type` over `interface`.
- No anonymous functions at module level.
- Avoid IIFEs. Prefer a named function or direct initialization so the control flow is explicit.
- Functions with more than two parameters of a shared type must take a single options object instead.
- No default exports.
- Prefer pure, framework-agnostic functions over hooks.
- Destructure props in React component signatures.
- Self-close React components that have no children.
- Prefer `undefined` over `null`. Convert `null` from browser/library APIs to `undefined` at the boundary.
- Prefer default parameter values over nullish coalescing (`??`) when possible.
- Never use type assertions (`as`, `var!`). Maintain type safety. 
- Always annotate caught errors as `unknown` and assert them through a helper (e.g. `assertIsError`).
- Be intentional with optional properties:
  - `{ lines?: ConstructedLine[] }` — the key may be omitted.
  - `{ lines: ConstructedLine[] | undefined }` — the key must exist, but may be `undefined`.

## React State

- Don't sync state with `useEffect`. If a child's state change needs to affect a sibling or parent, hoist the state up to their common ancestor.
- Reserve `useEffect` for synchronizing with something truly external (a subscription, a DOM API, a non-React library) 
- Don't call `setState` inside a loop. Compute the final value first, then call `setState` once
- If you notice a single user action driving more than two or three state variables through a chain of effects and handlers, that's a sign the state is split across too many places, look for a way to collapse it into fewer, more directly-derived pieces of state 

## Testing

- For application-owned components, prefer tests through the real parent flow and assert user-visible behavior. Use direct component-level `rerender()` tests for shared component contracts or when the application flow would be disproportionately expensive to reproduce.
- Hoist variables relevant to why a test passes or fails into the test itself, not shared state.
- Do not throw in tests solely to narrow a value returned by a test helper. Type the helper to return the exact variant it constructs so callers can use the result directly.
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

- See `GLOBAL.md`'s "Recurring bad-test patterns" for the cross-language test-quality checklist, including hardcoding expected values instead of computing them with the same logic under test (tautological-by-construction).
