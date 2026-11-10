---
name: python-review
description: Python code review rules covering idioms, constructors, logging, configuration, and scope.
---

# Python Review

Use alongside the `code-review` skill for Python changes. Apply repository rules before general preferences.

## Comments and docstrings

- Prefer clear names and signatures over explanatory comments or redundant parameter documentation.
- Document non-obvious public contracts, domain terminology, and the reason for a workaround or invariant.
- Explain what the code does or link to its contract; do not appeal to a person's authority.
- Preserve existing useful comments.

## Idiomatic Python

- Prefer `Self`, `dict.pop`, `dict.setdefault`, set operations on dictionary views, and `removeprefix`/`removesuffix` when they express the operation directly.
- Use `zip(..., strict=True)` unless truncation is explicitly intended.
- Parenthesize mixed boolean and bitwise expressions when precedence is not immediately clear.
- Use explicit `is None` checks when zero or an empty string is a legitimate value.
- Keep one-use helpers inline when extracting them adds no clarity.

## Configuration

- Keep environment-specific URLs, hostnames, paths, and ports in typed configuration rather than application branches or default arguments.
- Require an explicit environment or use a safe non-production default for operations that are not safe to rerun.

## Construction and lifecycle

- Constructors should store validated fields rather than access a network or database, read files, spawn threads, or capture the current time.
- Use a named factory to load or bootstrap state and explicit lifecycle methods for starting and stopping resources.
- Inject a clock when time affects domain behavior. Tests should use a deterministic clock rather than wall-clock time or sleeps.
- Expose a public constructor that owns invariants instead of requiring callers to supply private fields.

## Logging

- Choose levels deliberately: startup identity at info, routine per-event activity at debug, noteworthy recoverable conditions at warning, and failures at error.
- Avoid logging an exception and immediately raising the same message when its caller already owns reporting.
- Bound log-line size instead of dumping complete tables, lists, or grids.
- Include operation identity, relevant identifiers, and outcomes while excluding credentials and sensitive payloads.
- Use existing timing helpers or histograms where available; use a monotonic clock when measuring elapsed time directly.
- Configure root logging at the application entry point. Library modules should obtain a logger without changing global formatting.

## Scope and maturity

- Keep renames, unrelated formatting, and incidental cleanup out of the behavior change.
- Follow the repository's existing approach to experimental code and compatibility; do not invent a new staging directory.
- Keep the feature diff readable independently of unrelated changes.

## Proportionate feedback

- Do not block a narrow change over trailing commas, equivalent formatting, or private-helper annotations unless a repository rule or concrete correctness concern applies.
- A short comprehension does not require longer variable names when the meaning is already clear.
- Suggest a one-liner only when it improves readability.
- Treat personal preferences as non-blocking and omit them when they would not materially improve maintainability.
