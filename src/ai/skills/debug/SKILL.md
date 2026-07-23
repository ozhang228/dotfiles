---
name: debug
description: Use when the user invokes /debug or when diagnosing a reproducible issue would otherwise require exploratory local scripts. Build the investigation as a reusable Marimo notebook in ~/forge/notebooks, extract genuinely reusable plumbing into notebooks/utils, and leave the resolved root cause and verification in the notebook.
---

# Debug

Turn debugging work into a reproducible Marimo investigation instead of a sequence of terminal probes or a throwaway script.

An explicit `/debug` invocation always uses this workflow. Without an explicit invocation, use it when the investigation needs live-system queries, data comparisons, repeated probes, or a local script. Skip it for obvious one-line fixes, build errors with a known cause, and mechanical lint/type failures.

## Artifact ownership

- Put every notebook in `/home/ozhang/forge/notebooks`, never in the target project.
- Run notebook commands from `/home/ozhang/forge` with its checked-in environment: `uv run marimo ...`.
- Read `/home/ozhang/forge/CLAUDE.md` and the target repository's instructions before investigating.
- Search existing notebooks and `notebooks/utils` before creating anything. Extend a notebook when it investigates the same system and class of failure.
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
5. **Root cause**: the evidence-backed explanation, including important disproven hypotheses when they would prevent repeated work.
6. **Resolution**: what changed in the target repository or external system.
7. **Result**: final status, verification output, remaining limitations, and the reusable takeaway for the next investigation.

The Result section is required before finishing. Write it into the notebook after the fix is verified; do not leave the conclusion only in chat. Preserve the failing reproducer alongside the fixed result when both can still be run safely.

## Marimo rules

- Follow the global Marimo rules in `~/dotfiles/src/ai/rules/marimo.md`.
- Put all imports in `with app.setup:`.
- Default cell-local names to a leading underscore. Return only values consumed by another cell.
- Give each UI control its own cell.
- Put a Markdown heading before each investigation phase.
- Prefer tables, plots, and pinned values that make the discrepancy visible over prose claims.
- Keep cells deterministic where possible. Show timestamps or snapshot identifiers when live data can change between runs.
- Parameterize the meaningful dimensions, not every constant. A notebook should be reusable for the same failure class without becoming a generic framework.

## Shared utilities

Use `/home/ozhang/forge/notebooks/utils/<domain>.py` for non-trivial plumbing that another notebook can reasonably reuse, such as:

- authenticated client construction;
- live snapshot acquisition;
- Kafka consumption and schema decoding;
- repeated response parsing or normalization;
- domain identifiers shared across investigations.

Keep incident-specific filters, comparisons, hypotheses, and presentation in the notebook. Do not extract a helper merely to shorten one notebook. Utilities must take important inputs explicitly, return typed data, and avoid hidden mutable state.

Before adding a helper, search `notebooks/utils` for an existing domain module. Extend that module when the abstraction matches; create a new one only for a distinct domain.

## Investigation standards

- Reproduce through the real production path before claiming what production does. Test fixtures and stubs are not evidence of production configuration.
- Record which facts are observed and which are inferred.
- Start with the reported symptom, then add probes that distinguish hypotheses. Do not dump unrelated system state into the notebook.
- Keep credentials out of cells and outputs. Use the established clients and credential providers.
- Redact tokens, user data, and oversized payloads before rendering results.
- If a probe mutates production state, stop and get explicit approval first.
- If the issue cannot be reproduced, leave the attempted inputs, observed result, and next discriminating probe in the Result section.

## Workflow

1. Read target and Forge instructions.
2. Search existing notebooks and utilities for the same system and failure shape.
3. Create or extend the notebook before running exploratory probes.
4. Reproduce the symptom with the smallest live path.
5. Add one evidence-producing probe at a time until the root cause is supported.
6. Extract reusable plumbing only after its reusable boundary is clear.
7. Fix the target repository and add focused regression tests there.
8. Re-run the notebook against the fixed behavior or record why verification must differ.
9. Complete the Root cause, Resolution, and Result sections.
10. Validate from `/home/ozhang/forge`:

```bash
uv run marimo check --strict notebooks/<name>.py
```

Run the notebook when its dependencies and live-system access are available. Use:

```bash
uv run marimo edit notebooks/<name>.py --host 0.0.0.0 --headless --watch
```

Keep the server running while Oscar reviews the investigation, and report the reachable workstation URL with its token. Also report the notebook path, the root cause, the production verification performed, and any live checks that could not be run.
