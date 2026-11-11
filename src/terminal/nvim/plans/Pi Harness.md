# Pi Harness

Replace Claude Code and Codex with Pi while preserving the workflows I actually use. Sandboxing and recoverable changes are required before switching.

## Required before switching

- [ ] Verify installation, symlinks, and native isolation/recovery smoke tests on remaining Ubuntu and Manjaro machines
- [ ] Reduce cold whole-repository checkpoint cost in dependency-heavy repositories without losing recovery coverage
- [ ] Keep sandbox-generated protected config placeholders out of broad formatter/file scans
- [ ] Add explicitly scoped worker network and external capabilities
  - [ ] Start with an explicit domain allowlist for documentation and project package registries; keep other destinations blocked
  - [ ] Give workers private dependency caches and repo-local virtual environments/node_modules; keep shared host caches protected
  - [ ] Verify a real dependency install and test run, blocked destinations, and sandboxed lifecycle scripts before expanding access
  - [ ] Verify DNS, TLS, proxies, timeouts, and errors; then add explicitly scoped APIs, databases, and MCP services
  - [ ] Use host brokers or scoped credential injection; reusable credentials and privileged host sockets stay inaccessible
  - [ ] Expose only needed host diagnostics through a scoped read-only interface
  - [ ] Scope external writes independently of model instructions; retain protected default branches and existing Git/external-action rules
- [ ] Extend local Git support without weakening the sandbox
  - [ ] Support read-only Git inspection in linked worktrees whose metadata is outside the launch repo
  - [ ] Add explicitly requested local commits later; keep Git metadata read-only until then
  - [ ] Add push and draft PR creation only with explicit approval and scoped authentication
- [ ] Preserve worktree and editor integration
  - [ ] Switch AI_CLI_CMD to ai-resume --agent pi when ready; keep the existing Snacks terminal toggle on ai-resume --agent codex --no-daemon for now
  - [ ] Check Neovim/tmux startup, resume, Ctrl+C, resize, scrollback, and immediate LazyGit changes
  - [ ] Verify @file:line and @file:start-end references through Pi
  - [ ] Verify linked-worktree separation and moved session directories
- [ ] Verify remaining instruction and skill integration
  - [ ] Verify ancestor/project AGENTS.md and CLAUDE.md discovery
  - [ ] Verify brainstorm, debug, postmortem, and applauncher-use through Pi
  - [ ] Audit skill assumptions about tool names, delegation, model routing, questions, and local artifacts; adapt only incompatible harness contracts
  - [ ] Verify rule loading stays scoped; adapt debug/postmortem to the investigation workflow chosen below
- [ ] Configure the MCP tools I use
  - [ ] Migrate developer, Slack read-only, Polaris, Grafana, Splunk, and OpenAI documentation servers to Pi's native MCP configuration
  - [ ] Preserve per-tool exposure restrictions, authentication, timeouts, and useful server descriptions
  - [ ] Verify a real read-only call against each required service through the sandbox
  - [ ] Verify native codemode/tool search with the required services: bounded output, parallel independent calls, and ordered errors/results
  - [ ] Add the historical TAPS position-query server only if still needed and accessible
- [ ] Add managed long-running jobs, dev servers, and watchers
  - [ ] Add or select managed background jobs with stable IDs, bounded incremental output, status, exit codes, cancellation, and process-tree cleanup
  - [ ] Support long tests, benchmarks, local servers, and notebooks while continuing the conversation
  - [ ] Support interactive stdin or PTY sessions where required; verify whether existing Pi facilities cover each case before adding a tool
  - [ ] Scope server ports, bind to 0.0.0.0, and verify process-tree cleanup after cancellation and harness exit
  - [ ] Define recovery for writes made after a launch command returns; keep jobs and writable paths inside the sandbox
- [ ] Rethink the memory and debugging system beyond Anvil
  - [ ] Define what is missing from keeping notebooks and postmortems in one place: finding previous work, resuming investigations, rerunning evidence, or recalling useful findings
  - [ ] Decide where investigations, reproducible notebooks, postmortems, reusable helpers, and durable knowledge belong and how they connect
  - [ ] Design how I and the agent find relevant previous work, with source links and clear handling of stale findings
  - [ ] Simplify investigation capture and closeout; decide when a notebook or postmortem is useful instead of requiring one for every task
  - [ ] Keep wiki maintenance out of active debugging; capture only the evidence needed to investigate and resume
  - [ ] Make /postmortem proactively write the incident record and promote verified, reusable findings into the relevant wiki pages, linking to evidence and updating existing pages rather than appending duplicate recaps
  - [ ] Keep wiki pages and investigation records together in one knowledge repository; use focused topic/system pages and a small navigation index
  - [ ] Give each wiki page a clear scope, supporting sources, and last-verified date; label historical observations with their environment and date
  - [ ] Give Pi bounded search/read access to the wiki and postmortems; load a small navigation guide instead of the whole archive
  - [ ] Add knowledge_search returning short excerpts, source links, and verification dates; start with full-text search and add semantic search only if wording differences cause useful results to be missed
  - [ ] Make relevant knowledge lookup part of system-specific work; /debug also searches previous investigations before starting new probes
  - [ ] Decide whether automatic lookup runs for every work task or only investigations and unfamiliar systems; evaluate a Pi extension that retrieves initial context
  - [ ] Make /postmortem search existing pages before editing, resolve or mark superseded claims, and record unresolved contradictions; collect conflicts found during debugging for closeout
  - [ ] Report pages updated, contradictions resolved, and unresolved questions after /postmortem so maintenance is reviewable
  - [ ] Verify wiki retrieval and maintenance through real investigations, including finding an existing answer and correcting an outdated page
  - [ ] Try the proposed workflow on a real investigation before migrating existing Anvil artifacts; preserve the originals
- [ ] Implement cross-session memory after agreeing on that design
  - [ ] Reuse canonical rules and durable knowledge instead of copying incident recaps into new files
  - [ ] Provide searchable previous-conversation and memory files with source/session references
  - [ ] Add task-relevant memory lookup/injection at session start or before work; keep it bounded and distinguish historical facts from current verification
  - [ ] Treat invoking /postmortem as authorization for relevant wiki updates; keep other durable writes explicitly requested and distinguish reusable knowledge from investigation history
  - [ ] Keep old Claude/Codex logs available for read-only search; evaluate Pi import separately rather than assuming lossless conversion
- [ ] Verify native conversation behavior
  - [ ] Exercise queued steering and follow-up messages during active tools; preserve task direction and cancellation
  - [ ] Exercise automatic/manual compaction and resume with important constraints retained
  - [ ] Verify file/image input and clipboard behavior

## Follow-up work

- [ ] Add completion/waiting notifications only if wanted; verify actual hooks instead of copying stale hook trust entries
- [ ] Improve questions during ongoing work
  - [ ] Evaluate an asynchronous question UI that leaves independent work running; current history uses nonblocking question tools
- [ ] Evaluate agent-side LSP
  - [ ] Measure useful definition/reference/diagnostic calls before porting the configured Python, TypeScript, C++, and Rust integrations
  - [ ] Reuse installed language servers and leave Neovim's own LSP independent
- [ ] Evaluate infrequently used harness features
  - [ ] Add persistent goal/token-budget tracking only if wanted; it has much less recorded use than sessions, tools, and subagents
  - [ ] Add native browser/search integrations only when shell-based browser tooling, image input, and documentation MCP are insufficient

## Plugin shortlist to review

Candidates for exploration; most will be skipped. Prefer one package per responsibility. Source versions below do not establish runtime compatibility.

- [ ] Review additional packages for useful features and overlap
  - [ ] [@dietrichgebert/ponytail](https://pi.dev/packages/@dietrichgebert/ponytail)
  - [ ] [billion-context](https://pi.dev/packages/billion-context)
  - [ ] [pi-web-access](https://pi.dev/packages/pi-web-access)
  - [ ] [@postman/postman-plugin](https://pi.dev/packages/@postman/postman-plugin)
  - [ ] [@juicesharp/rpiv-ask-user-question](https://pi.dev/packages/@juicesharp/rpiv-ask-user-question)
  - [ ] [@onkernel/browser-loop](https://pi.dev/packages/@onkernel/browser-loop)
  - [ ] [context-mode](https://pi.dev/packages/context-mode)
  - [ ] [@plannotator/pi-extension](https://pi.dev/packages/@plannotator/pi-extension)
  - [ ] [pi-tidy-memory](https://github.com/mikeyobrien/pi-tidy-tools/tree/main/packages/pi-tidy-memory)
  - [ ] `pi-fff` — fast fuzzy search (`ffgrep` / `fffind`)
  - [ ] `rpiv-todo` — todo tool
  - [ ] `pi-computer-use` — desktop/GUI automation
  - [ ] `pi-session-recall` — search and query past sessions
  - [ ] `npm:@narumitw/pi-btw`
  - [ ] `npm:pi-observational-memory`
  - [ ] `@feniix/pi-devtools`
  - [ ] `@gwynnnplaine/pi-github`

- [ ] Review the core plugin candidates
  - [ ] Review [pi-interactive-shell](https://github.com/nicobailon/pi-interactive-shell) for managed jobs and PTYs
    - [ ] Source version 0.18.0 provides stable session IDs, input, status, background dispatch, and user takeover; verify build/test/server workflows inside the sandbox
    - [ ] Disable automatic quiet-close for servers; its kill result can mean supervision ended without confirmed process exit, so verify actual process-tree termination
    - [ ] Review its default 24-hour saved-log cleanup and overlay behavior against recoverability and the compact tool display
  - [ ] Review [pi-memory](https://github.com/jayzeng/pi-memory) for portable Markdown memory
    - [ ] Source version 0.4.2 declares Pi >=0.81.1; review bounded injection, plain files, optional qmd search, and memory_forget/memory_restore recovery records
    - [ ] Disable default exit-summary generation with PI_MEMORY_EXIT_SUMMARY=0 and enforce explicit authorization for durable writes; its memory recovery does not protect arbitrary workspace files
    - [ ] Point retrieval at canonical knowledge where supported; avoid creating a competing incident-history store or another task checklist
  - [ ] Review [pi-session-search](https://github.com/samfoy/pi-session-search) for previous-conversation lookup
    - [ ] Review incremental worker-thread indexing, search/read tools, project session primer, embedding-provider configuration, and bounded results
    - [ ] Verify Claude/Codex archive ingestion separately; the documented native locations are Pi sessions and Pi session archives
  - [ ] Review [pi-knowledge-search](https://github.com/samfoy/pi-knowledge-search) for canonical notes and rules
    - [ ] Review local-file indexing, BM25/vector retrieval, source excerpts, kb_read, and startup overview budgets against existing anvil/dotfiles knowledge
    - [ ] Keep sensitive notes local unless a configured embedding service is authorized; use only required directories and verify behavior when embeddings fail

- [ ] Compare optional plugins only where they improve my workflow
  - [ ] Compare [pi-total-recall](https://github.com/samfoy/pi-total-recall) with individually selected memory/search components
    - [ ] Source version 1.9.2 bundles @samfp/pi-memory, pi-session-search, and pi-knowledge-search; it is an alternative to the separate memory stack, not another layer to install alongside it
    - [ ] Its memory component automatically extracts lessons on session end; require a verified way to disable that or exclude the component to preserve explicit-user-request-only memory updates
    - [ ] Watch the package-name collision: jayzeng's pi-memory and samfoy's @samfp/pi-memory are different implementations
  - [ ] Review [pi-lsp-extension](https://github.com/samfoy/pi-lsp-extension) for a focused agent-side LSP
    - [ ] Source version 1.4.0 provides diagnostics, hover, definitions, references, symbols, and rename previews; verify basedpyright/tsgo/clangd/rust-analyzer configuration
    - [ ] Keep its background/shared language-server daemons inside the sandbox and distinguish tree-sitter fallback from real semantic LSP results
  - [ ] Compare [pi-lens](https://github.com/apmantza/pi-lens) with the narrower LSP option
    - [ ] Source version 4.4.9 adds LSP, linters, formatters, autofix, and broader post-write checks; disable unsolicited formatting/autofix and duplicated test pipelines before considering it
    - [ ] Inspect dependency/lifecycle-script requirements and output volume; choose it only if the extra checks are useful
  - [ ] Review [pi-notify](https://github.com/ferologics/pi-notify) for completion notifications
    - [ ] Source version 1.4.0 uses terminal OSC protocols and tmux passthrough; my tmux config already enables passthrough, but verify delivery through the actual Snacks/Kitty/tmux setup
  - [ ] Review selected [mitsupi / agent-stuff](https://github.com/mitsuhiko/agent-stuff) utilities
    - [ ] Source version 1.6.0 includes session control, goal tracking, question answering, review, usage breakdown, notifications, and other extensions
    - [ ] Select only needed files; do not enable its separate todos store, automatic GitHub trust, uv restrictions, or alternate review workflow by default
    - [ ] Consider answer/control/goal/session-breakdown individually

- [ ] Test selected plugins inside the existing sandbox
  - [ ] Verify Pi/Node compatibility, licenses, ownership, dependencies, and lifecycle scripts; run each package's relevant tests in isolation
  - [ ] Verify combined load order, tool replacements, codemode, MCP, and managed jobs through the actual editor workflow
  - [ ] Recheck isolation, recovery, cancellation, and process cleanup with selected plugins loaded
