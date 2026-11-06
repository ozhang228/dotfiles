# Pi Harness

Replace Claude Code and Codex with Pi while preserving the workflows I actually use. Focus mode, sandboxing, and recoverable changes are required before switching.

## Required before switching

- [ ] Establish the Pi baseline
  - [ ] Pin a supported Pi release and extension versions; this audit checked v1.5.0, which already includes MCP and codemode
  - [ ] Verify installation and symlinks on other machines before switching them to Pi
- [ ] Verify the existing model gateway
  - [ ] Verify real streamed responses, tool calls, reasoning levels, cancellation, usage reporting, and provider errors through the gateway
  - [ ] Support switching between the Claude and OpenAI models I use without losing the active conversation
- [ ] Verify sandboxed Pi on each Ubuntu and Manjaro machine
  - [ ] Run the native isolation/recovery smoke test; check AppArmor or namespace restrictions when startup fails
  - [ ] Check actual Neovim/tmux startup, resume, Ctrl+C, resize, scrollback, and immediate LazyGit changes
  - [ ] Exercise real builds and formatters in larger repositories; measure checkpoint cost beyond dotfiles
  - [ ] Extend recovery tests to interrupted exports, edits made concurrently by host programs, and host-controller death while a worker still holds the repo operation lock
- [ ] Add explicitly scoped worker network and external capabilities
  - [ ] Start with an explicit domain allowlist for documentation and project package registries; keep other destinations blocked
  - [ ] Give workers private dependency caches and repo-local virtual environments/node_modules; keep shared host caches protected
  - [ ] Verify a real dependency install and test run, blocked destinations, and sandboxed lifecycle scripts before expanding access
  - [ ] Verify DNS, TLS, proxies, timeouts, and errors; then add explicitly scoped APIs, databases, and MCP services
  - [ ] Use host brokers or scoped credential injection; reusable credentials and privileged host sockets stay inaccessible
  - [ ] Expose only needed host diagnostics through a scoped read-only interface
  - [ ] Enforce writable external operations independently of prompt instructions; preserve explicit push/deploy/restart approval, protected default branches, draft PRs, and no GitHub review-conversation mutations
  - [ ] Bind approval to the concrete action; skills, repository content, and tool results cannot supply authority
- [ ] Extend local Git support without weakening the sandbox
  - [ ] Support read-only Git inspection in linked worktrees whose metadata is outside the launch repo
  - [ ] Add explicitly requested local commits later; keep Git metadata read-only until then
  - [ ] Add push and draft PR creation only with explicit approval and scoped authentication
- [ ] Add sandboxed dev servers and watchers after the foreground-command version
  - [ ] Extend the host controller with supervised jobs, scoped ports, cancellation, and verified process-tree cleanup
  - [ ] Define recovery for writes made after a launch command returns; do not silently bypass the checkpoint guarantee
  - [ ] Reuse the same controller boundary for statically configured extra repos, with separate scope and recovery accounting
  - [ ] Verify recovery and process cleanup for background jobs and future subagents
- [ ] Add focus mode
  - [ ] Add a command and shortcut to toggle focus mode and remember the preference
  - [ ] Hide tool call headers, arguments, streaming output, results, images produced by tools, and subagent tool chatter from the visible transcript
  - [ ] Keep user messages, assistant progress/answers, a compact running/waiting indicator, and required approval requests visible
  - [ ] Report actionable failures concisely without dumping raw tool output
  - [ ] Preserve full tool events and results for model context, local history, debugging, and later inspection; hiding is presentation-only
  - [ ] Allow revealing the complete transcript during or after work, including after resume
  - [ ] Try Pi's global tool-renderer extension API first; verify whether it can remove outer spacing and all tool images, and make a narrow TUI change only if needed
  - [ ] Verify in the actual Neovim Snacks terminal and tmux, including streaming, failures, approval prompts, cancellation, and resumed sessions
- [ ] Preserve worktree and editor integration
  - [ ] Switch AI_CLI_CMD to ai-resume --agent pi when ready; keep the existing Snacks terminal toggle on ai-resume --agent codex --no-daemon for now
  - [ ] Verify the current @file:line and @file:start-end mappings; translate references if Pi does not resolve their existing syntax correctly
  - [ ] Verify linked-worktree separation and moved session directories
- [ ] Reuse existing instructions and skills
  - [ ] Verify ancestor/project AGENTS.md and CLAUDE.md discovery
  - [ ] Verify skill workflows through Pi, including brainstorm, code-review, debug, postmortem, and applauncher-use
  - [ ] Audit skill assumptions about tool names, delegation, model routing, questions, and local artifacts; adapt only incompatible harness contracts
  - [ ] Keep familiar /brainstorm and /code-review entry points through aliases/templates if desired; Pi's native commands use /skill:name
  - [ ] Verify rule loading stays scoped; adapt debug/postmortem to the investigation workflow chosen below
- [ ] Configure the MCP tools I use
  - [ ] Migrate developer, Slack read-only, Polaris, Grafana, Splunk, and OpenAI documentation servers to Pi's native MCP configuration
  - [ ] Preserve per-tool exposure restrictions, authentication, timeouts, and useful server descriptions
  - [ ] Verify a real read-only call against each required service through the sandbox
  - [ ] Verify native codemode/tool search with the required services: bounded output, parallel independent calls, and ordered errors/results
  - [ ] Add the historical TAPS position-query server only if still needed and accessible
- [ ] Preserve long-running command control
  - [ ] Add or select managed background jobs with stable IDs, bounded incremental output, status, exit codes, cancellation, and process-tree cleanup
  - [ ] Support long tests, benchmarks, local servers, and notebooks while continuing the conversation
  - [ ] Support interactive stdin or PTY sessions where required; verify whether existing Pi facilities cover each case before adding a tool
  - [ ] Bind local development servers to 0.0.0.0 and preserve the existing tmux process-cleanup behavior
  - [ ] Keep jobs and their writable paths inside the sandbox; define what survives harness exit and what must stop
- [ ] Add subagent support
  - [ ] Start from Pi's bundled subagent example or an existing package; add only the coordination behavior used by the existing skills
  - [ ] Support spawn, task delivery, results, status, follow-up work, wait, interruption, and messages between parent and workers
  - [ ] Preserve explicit model/effort selection where skills require it and inherit the parent's sandbox and authorization limits
  - [ ] Make shared-workspace edit ownership explicit and verify actual tests after delegated edits
  - [ ] Surface concise worker status in focus mode and preserve full worker logs for inspection
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
  - [ ] Verify model/thinking selectors, file/image input, context/usage display, and clipboard behavior

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

These are candidates, not an approved install set. Reviewed repository READMEs, package manifests, and selected implementation paths on 2026-11-05. Versions below are from repository manifests, not independently verified npm releases. Nothing was installed or executed. Prefer one package per responsibility and load selected resources from bundles rather than enabling everything.

- [ ] Check additional packages (not yet reviewed; exploration only, most may be skipped; verify overlap with existing candidates)
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
  - [ ] `npm:pi-sandbox`
  - [ ] `npm:@narumitw/pi-btw`
  - [ ] `npm:pi-observational-memory`
  - [ ] `pi-lens`
  - [ ] `@feniix/pi-devtools`
  - [ ] `@gwynnnplaine/pi-github`

- [ ] Review the core plugin candidates
  - [ ] Review [pi-subagents](https://github.com/nicobailon/pi-subagents) for delegation
    - [ ] Source version 0.85.0 requires Pi 1.2.0 or newer; compare foreground/background children, fleet inspection, steering, stop, result delivery, and model selection with my existing skill contracts
    - [ ] Verify in-process and detached children inherit the full-process sandbox and chosen permission layer; do not assume integration with a different author's permission plugin
  - [ ] Review [pi-interactive-shell](https://github.com/nicobailon/pi-interactive-shell) for managed jobs and PTYs
    - [ ] Source version 0.18.0 provides stable session IDs, input, status, background dispatch, and user takeover; verify build/test/server workflows inside the sandbox
    - [ ] Disable automatic quiet-close for servers; its kill result can mean supervision ended without confirmed process exit, so verify actual process-tree termination
    - [ ] Review its default 24-hour saved-log cleanup and overlay behavior against recoverability and focus mode
  - [ ] Review [@gotgenes/pi-permission-system](https://github.com/gotgenes/pi-packages/tree/main/packages/pi-permission-system) for action approvals
    - [ ] Source version 42.0.0 declares Pi >=1.0.0; review allow/ask/deny policies, canonical paths, fail-closed gate errors, unknown shell commands, and MCP access
    - [ ] Use the current monorepo; the old standalone repository is archived because it moved
    - [ ] Verify indirect codemode calls and all child execution paths; its documented automatic integration is with @gotgenes/pi-subagents, not necessarily nicobailon's package
    - [ ] Keep automated authorizer/model-judge extensions off initially; explicit push/deploy approval must remain mine
  - [ ] Review [cc-safety-net](https://github.com/kenryu42/cc-safety-net) for destructive-command checks
    - [ ] Source version 2.7.3 includes a Pi extension and semantic command checks; compare its destructive Git, filesystem, and secret-access coverage with my rules
    - [ ] Treat it as an additional guard: its documentation explicitly says it is not a sandbox and it provides no general filesystem recovery
    - [ ] Inspect configuration-error fallback to defaults and any override controls; ensure they cannot weaken mandatory action policies
  - [ ] Review [agents-sandbox](https://github.com/inoio/agents-sandbox) for whole-agent isolation
    - [ ] This is a launcher, not a Pi extension; evaluate its per-project microVM, scoped network, host-side secret injection, Linux/KVM, and macOS requirements
    - [ ] Its default workspace sharing is read/write; choose a protected copy/overlay and independently recoverable apply boundary before accepting it
    - [ ] Verify Neovim/tmux attachment, Portkey/MCP connectivity, local server access, subagents, and recovery after crashes
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
    - [ ] Check whether waiting-for-approval notifications need a separate event handler; the documented main trigger is agent completion
  - [ ] Review selected [mitsupi / agent-stuff](https://github.com/mitsuhiko/agent-stuff) utilities
    - [ ] Source version 1.6.0 includes session control, goal tracking, question answering, review, usage breakdown, notifications, and other extensions
    - [ ] Select only needed files; do not enable its separate todos store, automatic GitHub trust, uv restrictions, or alternate review workflow by default
    - [ ] Consider answer/control/goal/session-breakdown individually; the bundled subagent extension is serial and may not cover my parallel review workflow

- [ ] Keep these candidates on hold until their gaps are resolved
  - [ ] Review [carderne/pi-sandbox](https://github.com/carderne/pi-sandbox) only with an independent fail-closed launcher
    - [ ] Source version 0.8.0 declares a ^0.80.0 Pi peer range, which excludes 1.5.0; resolve compatibility before installation
    - [ ] Its initialization failure clears sandboxEnabled and its bash wrapper uses ordinary operations when disabled; fix or contain this fallback before use
    - [ ] It gates built-in file tools and sandboxes bash, not the entire agent/extension process; documented Linux write globs are ignored by the OS backend and the browser sample opens security loopholes
  - [ ] Review [@oddsjam/pi-sandbox](https://github.com/oddsjam/pi-sandbox) only with an independent fail-closed launcher
    - [ ] Source version 0.1.0 gates built-in tools but explicitly leaves Pi itself unsandboxed; its bash wrapper calls localBash when initialization/enabling is false
    - [ ] A startup failure therefore does not satisfy my mandatory sandbox boundary; also inspect weaker network isolation defaults, child tools, and rollback coverage
  - [ ] Review Pi's [git-checkpoint example](https://github.com/earendil-works/pi/blob/v1.5.0/packages/coding-agent/examples/extensions/git-checkpoint.ts) only as an illustration
    - [ ] It uses git stash create, keeps refs in an in-memory map, clears them after a run, and applies a stash when asked; it is not persistent recovery and does not capture untracked/ignored files
    - [ ] Do not use it to satisfy the no-unrecoverable-deletion requirement
  - [ ] Avoid [pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter) and [pi-mcp-extension](https://github.com/irahardianto/pi-mcp-extension) unless a concrete unsupported transport requires one
    - [ ] Native Pi 1.5.0 already handles the HTTP MCP services I use; additional clients duplicate tool discovery and authentication

- [ ] Approve a concrete plugin combination after verification
  - [ ] Verify published versions, supported Pi/Node versions, licenses, active repository ownership, dependency trees, and lifecycle scripts; pin exact versions or commits
  - [ ] Run each candidate's actual relevant tests against the pinned tree in isolation; README and manifest compatibility do not prove runtime compatibility
  - [ ] Verify the combined load order and tool replacements, especially bash, edit/write, permission hooks, codemode, detached jobs, and subagents
  - [ ] Reject a required safety component if installation/loading fails or the sandbox is unavailable; Pi's ordinary package-loading behavior can warn and continue without a failed package
  - [ ] Recheck isolation and recovery with selected plugins loaded; verify they cannot bypass the controller or access recovery storage
  - [ ] Exercise gateway/MCP reads, delegated edits, long tests, interactive shells, cancellation, compaction/resume, and focus-mode approvals through the actual editor workflow
  - [ ] Resolve remaining integration gaps before making Pi the editor default

Discovery sources: [Pi package gallery](https://pi.dev/packages) and each repository linked above. Repository inspection identified specific limits; no plugin has been certified safe or compatible end to end. General npm search was unavailable during discovery, so exact publication/install verification remains a checklist item.

## Evidence and verification limits

Audited the current dotfiles, local Claude/Codex history indexes, all 1,193 retained Codex JSONL files, and all three retained Claude project transcripts. Retained logs include imported conversations and worker sessions, so counts below are recorded occurrences rather than unique tasks. Local history indexes contain 18,338 Codex entries and 12,116 Claude entries; some historical features have since changed.

Claude history contains 70 /code-review, 31 /brainstorm, 113 /model, 162 /clear, and 30 /compact entries. Local Claude metadata records 1,436 prompt-queue uses. Codex logs contain 764 spawn_agent calls across 153 files, 36,467 nested write_stdin calls across 510 files, and 584 nonblocking question calls across 108 files. MCP use is substantial: 2,953 Splunk queries, 694 Slack searches, 410 Prometheus queries, and 165 Polaris calls. Image inspection and compaction also appear repeatedly. These demonstrate workflow dependencies; configured Claude LSP plugins alone do not prove agent-side LSP use.

Current Codex configuration uses Portkey with the Responses API, enabled memory, disabled web search, and unrestricted local permissions. Those unrestricted permissions describe the current setup; the requested Pi sandbox is a stronger requirement. Old hook trust records exist, but the referenced global hooks file was absent during this audit.

Pi behavior was checked against source/docs for released v1.5.0 and current documentation. Pi already supports MCP, skills, context files, sessions, steering, compaction, model settings, and codemode. Its security documentation explicitly says project trust does not sandbox tools. Focus mode, gateway/MCP integration, and sandbox verification on other machines remain pending.

Sources: [Pi v1.5.0](https://github.com/earendil-works/pi/releases/tag/v1.5.0), [security](https://github.com/earendil-works/pi/blob/v1.5.0/packages/coding-agent/docs/security.md), [MCP](https://github.com/earendil-works/pi/blob/v1.5.0/packages/coding-agent/docs/mcp.md), [extensions](https://github.com/earendil-works/pi/blob/v1.5.0/packages/coding-agent/docs/extensions.md), [skills](https://github.com/earendil-works/pi/blob/v1.5.0/packages/coding-agent/docs/skills.md), and [official OpenAI documentation](https://learn.chatgpt.com/docs/developer-commands).
