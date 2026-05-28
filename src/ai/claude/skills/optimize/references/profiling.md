# Profiling

Profile as close to production as possible. A benchmark that doesn't reflect production conditions gives you a number, not an answer.

## Rules before you start

- Use production data (or a snapshot) — not synthetic inputs
- Run the full application path, not just the function you suspect
- Match the execution environment (same process topology, workers, threads as prod)
- Measure 3+ times — if numbers vary >20%, find out why before reporting
- State what you're measuring: "mapper cycle time on crude live config" not "it's slow"

## CPU / call tracing: viztracer

```bash
pip install viztracer

# --min_duration prevents huge dump files. viztracer's own -m runs the module,
# so there is NO separate `python -m` — that form is invalid.
viztracer --min_duration 0.2ms -m my.module.main path/to/config.json

# in a uv project, prefix with `uv run` and keep viztracer's -m (NOT `uv run python -m`):
uv run viztracer --min_duration 0.2ms -m my.module.main path/to/config.json

# visualize
vizviewer result.json   # opens browser on port 9001
```

Teardown: press Ctrl-C **once** and wait for `result.json` to finish writing. Spamming Ctrl-C kills the dump.

**What to look for:**

- Widest bars = hottest functions
- Unexpected call counts (called 10,000×/cycle when it should be called once)
- Blocking I/O on the hot path that could be cached or moved to a background thread

Docs: https://viztracer.readthedocs.io/en/stable/basic_usage.html

## Memory profiling: memray

```bash
pip install memray

python -m memray run -m my_module
memray flamegraph <bin-file-name>

# live mode
memray run --live -m my_module
```

**What to look for:**

- Peak RSS — when does it spike?
- Allocations that grow over time (leak candidates)
- Large single allocations that could be chunked or streamed
- Allocations in tight loops that should be pre-allocated

Docs: https://github.com/bloomberg/memray

## What to report

Always include:

- Before / after in absolute units (ms, MB) — not just "2x faster"
- The bottleneck function with its % of total time
- The config and data used so someone can reproduce it

Example: "mapper cycle: 480ms → 110ms on crude live config. Bottleneck was `AttachFutureYtes` at 68% of cycle time"
