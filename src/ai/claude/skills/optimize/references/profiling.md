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
- **When a wrapper/accessor frame (`cached_property.__get__`, decorators, `functools` partials) tops tottime, do NOT dismiss it as a profiling artifact.** Run `pstats.Stats(f).print_callees('<file:lineno>')`: if the children's summed cumtime ≈ the frame's cumtime, the frame is a pass-through and the real cost is in children; if the frame's own tottime stays high after accounting for children, the overhead (locking, dict lookups, sheer call count) IS the bottleneck. A high call count (thousands) on a cheap-looking accessor is itself the signal.

Docs: https://viztracer.readthedocs.io/en/stable/basic_usage.html

## Profiling Dash / WSGI apps

`viztracer -m` silently fails for Dash apps — callbacks run on anyio worker-thread pools, so the main thread shows only `builtins.exec` and the worker lane comes up empty.

Three approaches, pick by need:

**1. Standalone driver (cleanest flame graph)**

Call the pure compute function directly in a `./tmp/` script, build the real API the way `main.py` does, wrap only the hot loop with `VizTracer`:

```python
from viztracer import VizTracer
with VizTracer(output_file="tmp/result.json", min_duration=200):
    for _ in range(N):
        compute_heatmaps(...)   # the function under test
```

Silence background-thread log noise first: `logging.getLogger("fio").setLevel(logging.WARNING)`.

**Footgun:** CLI `--include_files ./fio/...` matches against *absolute* paths, so relative paths silently filter the trace to nothing (looks identical to the worker-thread failure). Either pass absolute paths or use programmatic tracing scoped to the loop — the programmatic form is cleaner anyway.

**2. Werkzeug ProfilerMiddleware (real server path)**

Wraps the WSGI app so cProfile attaches to whichever thread handles the request — catches the actual worker thread:

```python
from werkzeug.middleware.profiler import ProfilerMiddleware
dash_app.server.wsgi_app = ProfilerMiddleware(dash_app.server.wsgi_app, profile_dir="tmp/profiles")
```

**Footgun:** `profile_dir` is relative to the *server's* cwd and cProfile does NOT create it — it dies mid-request with `FileNotFoundError` if missing. Create `python/tmp/profiles` before starting. cProfile inflates call-heavy code (plotly figure validation) in tottime; use it to identify dominant functions, not absolute latency.

**3. py-spy (best for live server, captures all threads natively)**

py-spy samples native thread stacks instead of using `setprofile`, so it captures pre-spawned anyio worker threads that viztracer misses:

```bash
uv pip install py-spy
py-spy record -o tmp/out.svg --pid <pid> --subprocesses --threads --idle --duration 30
```

Get the pid with `pgrep -f <app.entry_point>`. Needs ptrace perms (fine locally; pods have SYS_PTRACE). No code changes required.

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
