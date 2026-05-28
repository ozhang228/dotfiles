---
name: optimize
description: Guide a performance optimization session. TRIGGER when the user mentions "optimize", "speed up", "it's slow", "reduce latency", "memory usage", or similar. Profiling must come before code changes — optimization without a profile is guesswork. Covers the full cycle: profile → identify bottleneck → hypothesize → change one thing → re-profile → report.
---

# Optimize

You do not touch code until you have a profile that identifies the bottleneck.

**Scope: this skill is Python-only.** The tooling (viztracer, memray, see `references/profiling.md`) profiles Python processes. If the suspected bottleneck is in TypeScript / browser code, do NOT load the profiling reference — say so and pivot to Chrome DevTools (Performance tab for CPU, Memory tab for heap snapshots). Server-side Node has its own profilers (`node --prof`, clinic.js). Only continue with the workflow below when the target is a Python process.

**Profile against production, not synthetic inputs.** Spin up real clients with production config, feed them production-representative data, and time the full operation end-to-end. A microbenchmark on an isolated function misses I/O, serialization, cache effects, and integration overhead that dominate real-world latency. Only drill into a subfunction after the end-to-end measurement identifies it as the hotspot.

## Reference Guide

| Topic     | Reference                 | When                               |
| --------- | ------------------------- | ---------------------------------- |
| Profiling | `references/profiling.md` | First step — always run this first |

## Workflow

### 1. Define the question

Before profiling, nail down what you're actually measuring:

- What operation is suspected to be slow? ("the mapper cycle", "first request latency", "peak RSS during a 30s run")
- What data and config will you run with? Production data, production topology — not synthetic inputs
- What does "fast enough" look like? Without a target, you don't know when to stop

### 2. Profile

See `references/profiling.md`. Run with production data. Identify the top bottlenecks by % of total time before touching any code.

### 3. Hypothesize

Based on the bottleneck, form one concrete hypothesis before touching code:
- Name the specific function or allocation
- State the expected mechanism: "this is called N×/cycle but the result is pure and could be cached", "this allocates a new list on every tick", "this blocks on I/O synchronously"
- Predict the expected improvement: "should halve cycle time" or "should drop peak RSS by ~30%"

If you can't predict the improvement, your hypothesis is too vague. Sharpen it.

### 4. Change one thing

Make exactly one change. Bundling multiple changes means you can't attribute the improvement to any one of them. If you're tempted to batch, do them in sequence with a re-profile between each.

### 5. Re-profile

Run the exact same profiling setup as step 2. Compare:
- Before / after in absolute units — not just "2× faster"
- Did the bottleneck shrink? Did a new bottleneck emerge?
- Are you now at "fast enough" from step 1?

If not fast enough and a new bottleneck appeared, return to step 3 with the new bottleneck.

### 6. Report

State the result:
- What changed (one sentence)
- Before → after in absolute units
- The config and data used so someone can reproduce it
- Whether "fast enough" from step 1 was reached; if not, what the remaining bottleneck is

Example: "mapper cycle: 480ms → 110ms on crude live config. Bottleneck was `AttachFutureYtes` at 68% of cycle time. Now at target (<200ms). Remaining: `PriceUnderlyings` at 18% but within budget."
