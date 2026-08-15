---
name: postmortem
description: Use when Oscar says a debugging investigation is done, or invokes /postmortem. This is the explicit "the investigation is over" signal debug doesn't have on its own - closes out a debug notebook by pruning it to the minimal proof, extracting reusable plumbing to ~/anvil/utils, and writing a dated summary to ~/anvil/postmortems.
---

# Postmortem

Takes a finished `debug` notebook and produces three things: a pruned notebook, audited reusable utilities, and a dated markdown summary. `debug` optimizes for reaching the root cause fast and does none of this itself — invoke this only once Oscar confirms the investigation is actually over, never automatically at the end of a `debug` session.

## Input

The notebook path from the relevant `debug` session. Ask if ambiguous — search `~/anvil/notebooks` for the most recently modified file matching the discussed system/symptom.

## Step 1: Prune to the proof

Make a dedicated deletion pass on the notebook. The final notebook is a reusable proof, not a transcript of the investigation.

- Keep only the failing reproducer, the smallest control that validates units or assumptions, the evidence that distinguishes the root cause, final verification, and concrete handoff steps.
- Delete raw schema and payload dumps, broad source-column inventories, candidate matrices, samples, top-N difference tables, and disproven probes unless they prevent a likely repeat investigation.
- Collapse repeated evidence into the smallest table that shows the control and failure side by side. Preserve timestamps, formulas, exact source identifiers, and pinned values needed to interpret it.
- Re-run the pruned notebook from `~/anvil`: `uv run marimo check --strict notebooks/<name>.py`. Deletion is complete only when the minimal artifact still proves the conclusion end to end.

## Step 2: Extract and audit reusable utilities

Use `~/anvil/utils/<domain>.py` for non-trivial plumbing another investigation can reasonably reuse: authenticated client construction, live snapshot acquisition, Kafka consumption and schema decoding, repeated response parsing or normalization, domain identifiers shared across investigations.

- Search `~/anvil/utils` for an existing domain module before creating one. Extend a matching module; create a new one only for a genuinely distinct domain.
- Keep incident-specific filters, comparisons, hypotheses, and presentation in the notebook, not in utils. Do not extract a helper merely to shorten the notebook.
- Utilities must take important inputs explicitly, return typed data, and avoid hidden mutable state.
- If the notebook has ad hoc plumbing that duplicates or overlaps an existing `utils` module, consolidate into the module rather than leaving two versions.

## Step 3: Write the postmortem

File: `~/anvil/postmortems/YYYY_MM_DD-<slug>.md`, dated today. Use the debug notebook's own filename stem (without `.py`) as `<slug>` by default, so the postmortem and its source notebook are trivially pairable by name — only deviate if Oscar asks for a different slug.

Format:

```markdown
# <same title as the notebook's H1>

**Notebook:** `notebooks/<name>.py`

## Problem

<3-5 sentences: what broke, for whom or what system, how it was noticed>

## Root cause

<the evidence-backed explanation, one to a few sentences>

## How we debugged it

<the actual path to the root cause - which probes or evidence were decisive, in what order, including any dead ends worth knowing about>

## What to check next time

<concrete, actionable pointers for faster diagnosis next time this failure class recurs - specific logs, dashboards, queries, or commands that turned out to be the fastest signal>
```

Pull the content from the notebook's own Problem/Root cause/Result sections rather than re-investigating — postmortem summarizes, it doesn't re-derive.

## Workflow

1. Identify the notebook.
2. Prune it to the minimal proof (Step 1); re-run to confirm it still proves the conclusion.
3. Extract and audit reusable utilities (Step 2).
4. Write the postmortem markdown (Step 3).
5. Report the postmortem path, the notebook path, and a one-line summary of what changed in each (pruned by how much, any utils extracted or consolidated).
