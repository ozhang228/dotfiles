---
name: debug
description: Use when the user invokes /debug or when diagnosing a reproducible issue would otherwise require exploratory local scripts. Build the investigation as a reusable Marimo notebook in ~/anvil/notebooks and get to the root cause as fast as possible. Pruning and reusable-utility extraction happen later, in the `postmortem` skill, not here.
---

# Debug

Turn debugging work into a reproducible Marimo investigation instead of a sequence of terminal probes or a throwaway script. The one goal here is root cause, found fast without care for future use or doing things in a "clean way"

Use it when the investigation needs live-system queries, data comparisons, repeated probes, or a local script. Skip it for obvious one-line fixes, build errors with a known cause, and mechanical lint/type failures.

## Artifact ownership

- Put every notebook in `~/anvil/notebooks` unless given an explicit override
- Run notebook commands from `~/anvil` with its checked-in environment: `uv run marimo ...`.
- Search existing notebooks and postmortems before creating anything. Extend a notebook when it investigates the same system and class of failure. When multiple candidates match, prioritize the most recently updated ones first.
- Keep the production fix and its tests in the target repository. The notebook reproduces and explains the issue; it does not replace regression tests.
- Do not create a temporary script first. Start with the notebook and use its cells for probes.

## Naming and title

Choose a stable filename that describes the reusable problem shape:

```text
<system>_<observable_failure>.py
```

Prefer `opds_missing_historical_listings.py` over a ticket number, date, or one affected symbol. The first visible cell must be an H1 written like a postmortem title:

```markdown
# OPDS historical listings disappear before the service-wide data floor
```

During the investigation, name the symptom precisely. Once established, update the title to include the root cause without making it incident-specific.

## Notebook shape

Build a top-to-bottom narrative with these sections. Merge sections when the investigation is small, but preserve the order.

1. **Problem**: expected behavior, observed behavior, affected system, and the concrete input that reproduces it.
2. **Inputs**: standalone `mo.ui` cells for symbols, environments, dates, or other dimensions likely to vary next time.
3. **Reproduction**: the shortest live production code path that demonstrates the symptom.
4. **Evidence**: comparisons, intermediate values, counts, timelines, or source-by-source results that discriminate between hypotheses.
5. **Root cause**: a numbered, step-by-step trace of exactly how the failure occurs — see "Root cause must be a reproduction trace" below — plus important disproven hypotheses when they would prevent repeated work.
6. **Resolution**: what changed in the target repository or external system.
7. **Result**: final status, verification output, remaining limitations, and the reusable takeaway for the next investigation.

### Root cause must be a reproduction trace

A root cause section that states the conclusion without showing the path to it is not done. Write the Root cause section as a numbered sequence Oscar could follow and verify himself, not a paragraph asserting the answer:

```markdown
1. `refresh_session()` is called with a token that expired 3s earlier (`auth/session.py:41`).
2. Because `SESSION_TTL` is read from the *request-time* clock instead of the
   *issue-time* clock, the expiry check at line 44 passes even though the
   token is already stale.
3. The stale token is forwarded to `issue_token_hash()`, which does not
   re-validate expiry — it trusts the caller.
4. The downstream service receives a hash for an already-expired token and
   returns 401, which the caller surfaces as "random session drops."
```

Each step is a concrete, checkable fact (a file:line, an observed value, a branch actually taken) — not "eventually this causes X." If a step's claim came from a debugger inspection (a variable's actual runtime value, which branch actually executed, the actual call stack at failure) rather than from reading the code, say so inline, e.g. "`token.expires_at` was `12:03:41` at the point of failure (inspected live)." Someone reading only this section should be able to reconstruct the failure mentally without re-running the notebook.

The Result section is required before finishing. Write it into the notebook after the fix is verified; do not leave the conclusion only in chat. Preserve the failing reproducer alongside the fixed result when both can still be run safely.

## Marimo rules

- Follow the global Marimo rules in `~/dotfiles/src/ai/rules/marimo.md`.
- Default cell-local names to a leading underscore. Return only values consumed by another cell.
- Give each UI control its own cell.
- Put a Markdown heading before each investigation phase.
- Prefer tables, plots, and pinned values that make the discrepancy visible over prose claims.
- Keep cells deterministic where possible. Show timestamps or snapshot identifiers when live data can change between runs.
- Parameterize the meaningful dimensions, not every constant. A notebook should be reusable for the same failure class without becoming a generic framework.

## Runtime inspection via the debugger (mcp-debugger)

`mcp-debugger` (Python/debugpy, TypeScript-JS/js-debug, Rust/CodeLLDB) is available as an
MCP tool. Use it as an **evidence-gathering technique**, not a user-facing workflow 

- Which branch actually executes for a given live input.
- The actual value of a variable, or the actual call stack, at the moment of failure —
  especially when the value is computed far from where it is read.
- Ordering/interleaving questions (be aware: pausing execution changes timing, so a
  suspected race may not reproduce identically under the debugger — see below).

Do not reach for it when a log line, a print, or reading the code already settles the question — it is the heavier tool, not the default one.

**How to use it here:** attach or launch a session against the real reproduction path (the
same one the notebook's Reproduction cell uses), inspect the specific state needed, then
**transcribe the concrete observed values back into the notebook cell/prose as evidence** —
a pinned value, not a description of a debugger session. The debugger session itself is
scratch work; nothing about *how* the state was inspected belongs in the notebook except the
short "(inspected live)" provenance note called for above.

To inspect a running notebook's kernel state, have the notebook call `debugpy.listen(<port>)` once at the top (remove before finishing the investigation), then
attach `mcp-debugger` to that port. `debugpy` must be a dependency of the notebook's own environment (`uv add --dev debugpy` in `~/anvil`), not a global install.

## Investigation standards

- Reproduce through the real production path before claiming what production does. Test fixtures and stubs are not evidence of production configuration.
- Record which facts are observed and which are inferred.
- Start with the reported symptom, then add probes that distinguish hypotheses. Do not dump unrelated system state into the notebook.
- Keep credentials out of cells and outputs. Use the established clients and credential providers.
- Redact tokens, user data, and oversized payloads before rendering results.
- Default mutation-capable notebooks to dry run or read-only. Before any write,
  get explicit approval, require an explicit environment confirmation, snapshot
  the current state, reject concurrent changes, and verify exact readback.
- If the issue cannot be reproduced, leave the attempted inputs, observed result, and next discriminating probe in the Result section.

## Workflow

1. Read the target repository's instructions.
2. Search existing notebooks for the same system and failure shape.
3. Create or extend the notebook before running exploratory probes.
4. Reproduce the symptom with the smallest live path.
5. Add one evidence-producing probe at a time until the root cause is supported.
6. Fix the target repository and add focused regression tests there.
7. Re-run the notebook against the fixed behavior or record why verification must differ.
8. Complete the Root cause, Resolution, and Result sections.
9. Validate from `/home/ozhang/anvil`:

```bash
uv run marimo check --strict notebooks/<name>.py
```

Run the notebook when its dependencies and live-system access are available. Use:

```bash
uv run marimo edit notebooks/<name>.py --host 0.0.0.0 --headless --watch
```

Keep the server running while Oscar reviews the investigation, and report the reachable workstation URL with its token. Also report the notebook path, the root cause, the production verification performed, and any live checks that could not be run
