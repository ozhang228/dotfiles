---
name: optimize
description: Guide a performance optimization session. TRIGGER when the user mentions "optimize", "speed up", "it's slow", "reduce latency", "memory usage", or similar. Profiling must come before code changes — optimization without a profile is guesswork. Covers the full cycle: profile → identify bottleneck → hypothesize → change one thing → re-profile → report.
---

# Optimize

You do not touch code until you have a profile that identifies the bottleneck.

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

### 3. (rest of workflow — to be filled in)
