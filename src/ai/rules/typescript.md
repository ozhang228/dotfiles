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

## React Component Tests

- Test bodies never contain raw selectors or DOM traversal: no `querySelector`, `querySelectorAll`, `closest`, `children`, class or tag selectors, or `data-testid` strings.
- Separate rendering from page objects: `renderXyz(props)` mounts the component and returns a page object created by `createXyzPage(...)`. Page objects describe how a user sees and interacts with a component (for example `page.title.getText()`, `page.getLink("PRs").click()`, `page.getLink("PRs").keybinding.getKeys()`). Tests read as behavior and only call the page object.
- Page objects attach to an existing component; they never render it. Accept the DOM container directly (for example `createXyzPage(container, user)`), never a root getter or container callback. Scope queries with `within(container)` rather than global `screen`, and query elements when methods are called. For portalled content, pass the render result's `baseElement` as the container. Pass the render helper's shared `userEvent` instance to page objects that need interactions.
- Always put page objects in a `testHelpers/` directory at their owning layer, even when only one test uses them (for example `keyboard/testHelpers/KeyBindingHint.page.ts`). Export them so future tests can reuse them directly. Keep render helpers in the test files; never import a test file to reuse its helpers. Create `testHelpers/` directories where helpers exist rather than adding empty directories.
- Compose larger page objects from smaller ones. The parent locates and passes the child's container directly; the child's page object owns its internal selectors and interactions. Import child page objects from their owning layer's `testHelpers/` directory rather than duplicating their selectors in parent tests.
- Selectors live only inside the page object. Prefer accessible queries (role, name, label, text). If an element has no accessible handle, keep the one unavoidable structural selector inside the page object rather than spreading it across tests.
- Assert on pinned literals returned by the page object (`["⇧", "P"]`), not on counts or truthiness of elements.

## React State

- Don't sync state with `useEffect`. If a child's state change needs to affect a sibling or parent, hoist the state up to their common ancestor.
- Reserve `useEffect` for synchronizing with something truly external (a subscription, a DOM API, a non-React library) 
- Don't call `setState` inside a loop. Compute the final value first, then call `setState` once
- If you notice a single user action driving more than two or three state variables through a chain of effects and handlers, that's a sign the state is split across too many places, look for a way to collapse it into fewer, more directly-derived pieces of state 
