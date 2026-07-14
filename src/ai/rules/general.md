---
applies_to: All languages and projects
skip_if: Never — this always applies
---

# General

## Naming

- A name should say what a thing *is* or *does*, not how it's currently implemented or where it came from. Reject names that borrow jargon from one system to describe a concept in another (e.g. naming a general provider after a specific upstream dependency it happens to call today).
- If a name undersells fallible behavior (e.g. `query`, `get`, `fetch` for something that can raise or return an error), prefer a name that signals it, or route it through the project's established fallible-call convention.
- When picking between two reasonable names, prefer the one a new reader could guess the behavior of without opening the file.
