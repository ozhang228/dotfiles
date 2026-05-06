---
name: benchmark
description: Guide a performance benchmarking session. TRIGGER before any optimization work — "optimize", "speed up", "it's slow", "reduce latency", "memory usage". Benchmarking must come before code changes; profiling tells you which functions are worth touching. Covers production-realistic benchmarking principles and the two standard tools: viztracer (CPU/call tracing) and memray (memory profiling).
---

# Benchmarking

## When to use this skill

Any time the user mentions "optimize", "speed up", "it's slow", "reduce latency", "memory usage", or similar — invoke this skill **before touching any code**. Optimization without a profile is guesswork. The benchmark tells you which functions are worth the effort; everything else is premature.

The order is always: **measure first, then optimize**. Never the other way around.

## The core principle

**Benchmark as close to production as possible.**

A benchmark that doesn't reflect production conditions gives you a number, not an answer. Before running anything, verify:

1. **Use production data.** Run with actual production inputs or a snapshot of them — not synthetic data, not a toy config. If the concern is "it's slow on crude's live run", profile crude's live run.
2. **Run the full application path.** Profile the whole app first, not just the function you suspect. You'll often find the bottleneck is somewhere you didn't expect. Isolate a specific function only after the full-app trace confirms it's the hotspot.
3. **Match the execution environment.** Single-threaded microbenchmarks miss multiprocessing contention. Run with the same process topology (workers, threads, mp queues) as production. Viztracer handles this out of the box.
4. **Measure more than once.** A single run includes startup noise, cold cache effects, and JIT warmup. Run 3+ times and look for consistency. If numbers vary by >20%, find out why before reporting them.
5. **State what you're measuring.** "It's slow" is not a starting point. Identify the operation: "the first request latency", "the mapper cycle time", "peak RSS during a 30s window". Then measure that specifically.

## What to report

A benchmark without a comparison is just a number. Always show:

- **Before / after** if you changed something
- **Absolute time or memory** (ms, MB) not just relative speedup
- **The bottleneck function** from the flame graph with its % of total time
- **The config / data used** so someone can reproduce it

Bad: "it's 2x faster"
Good: "mapper cycle: 480ms → 110ms on crude live config. Bottleneck was `AttachFutureYtes` at 68% of cycle time (viztracer flame graph attached)"

## CPU / call tracing: viztracer

Low-overhead tracing with out-of-box multiprocessing support. Produces an interactive flame graph in the browser.

### Installation
```bash
pip install viztracer
```

### Run
Replace `python3` with `viztracer`. Always add `--min_duration 0.2ms` — without it the dump file becomes huge and details get lost.

```bash
# general pattern
viztracer --min_duration 0.2ms -m my.module.main path/to/config.json

# edo-risk example
viztracer --min_duration 0.2ms -m fio.app.edo_risk.main tests/example_config_cl.json
```

**Teardown is critical.** The profiler only dumps on graceful shutdown. Press Ctrl-C **once** and wait for the program to finish writing `result.json`. Spamming Ctrl-C kills the dump.

### Visualize
```bash
vizviewer result.json
```
Opens a browser on port 9001 with an interactive flame graph.

### What to look for in the flame graph
- The widest bars are the hottest functions — start there
- Look for unexpected call counts (a function called 10,000 times per cycle that should be called once)
- Look for blocking I/O (network/file calls) on the hot path that could be moved to a background thread or cached
- Look for functions that appear deep in unexpected call stacks (indicates a missing cache or redundant computation)

Official docs: https://viztracer.readthedocs.io/en/stable/basic_usage.html

## Memory profiling: memray

Tracks all Python heap allocations including native extensions and the interpreter itself. Generates a flame graph showing resident size and heap size.

### Installation
```bash
pip install memray
```

### Record and generate flame graph
```bash
python -m memray run -m my_module
memray flamegraph <bin-file-name>
```

### Live mode (watch memory in real time)
```bash
memray run --live -m my_module
```

### What to look for in the memray flame graph
- Peak resident memory — when does it spike?
- Allocations that grow over time (leak candidates)
- Large single allocations that could be streamed or chunked
- Allocations in tight loops that should be pre-allocated

Official docs: https://github.com/bloomberg/memray

## Process

1. **Define the question.** What operation are you measuring, with what data, at what scale?
2. **Full-app viztracer trace first.** Run with production config. Identify the top 2-3 hotspots by % of total time.
3. **Confirm memory baseline with memray if relevant.** Especially if the concern is RSS growth or OOM.
4. **Hypothesize the cause** of the hotspot before touching the code. Write it down.
5. **Make one change at a time.** Re-profile after each. Don't change three things and call it a win.
6. **Report with before/after numbers, the bottleneck function, and the config used.**
