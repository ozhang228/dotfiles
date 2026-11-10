`subagent` runs one to four named focused tasks with explicit parent-supplied context. Workers inherit the parent's active model and thinking level, return independently identified answers and log handles, then dispose their sessions. Only the parent edits repositories.

Ordinary sandboxed `pi` enables the extension. Children have `read`, `grep`, `find`, `ls`, and isolated `bash`; extension, skill, MCP, codemode, mutation, recovery, and delegation discovery are disabled. Bash has read-only repositories, no network/gateway sockets/credentials, and disposable scratch. Use `$TMPDIR` for scripts/reports and scratch cache variables for benchmarks. For pytest, use `--basetemp="$TMPDIR/tests" -p no:cacheprovider`. Commands requiring unavailable host tools or checkout writes fail explicitly.

Status shows one compact row per task. `subagent_log` pages recorded messages, tool requests/results, and diagnostics using `nextOffset`. Transcripts have a 2 MiB worker budget and 32 MiB total retention, with at most 16 batches; oldest completed batches expire. Exhaustion stops the affected worker explicitly. Logs end with the parent session and cannot resume workers.

Cancellation waits for SDK settlement and native command-tree termination before disposal and scratch cleanup. Cancelled admission IDs are retained up to 1,024 entries; exhaustion requires restarting Pi. Compact rendering and Ctrl+C cleanup have been checked through ordinary Pi in a local Ubuntu PTY; other distro terminals remain unverified.

Checks: `node --test src/ai/pi/plugins/subagents/*.test.mjs` and `cd setup && uv run pytest -q ../src/ai/pi/sandbox --tb=short`. Tests resolve the installed Pi runtime through the existing launcher discovery rather than a distro-specific path.
