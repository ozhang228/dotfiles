# Pi Harness

Replace Claude Code and Codex with Pi while preserving the workflows I actually use. Focus mode, sandboxing, and recoverable changes are required before switching.

## Required before switching

- [ ] Start with the smallest possible Pi setup and add one capability at a time
  - [x] Start from minimal settings, then customize ordinary `pi`: exclude discovered resources by default; whitelist DRW, bundled MCP/codemode/tool search, the dotfiles skills directory, and Catppuccin Macchiato; enable read-only tools and compaction, keep llama.cpp disabled, and set project trust to ask
  - [x] Keep only the existing DRW model provider enabled and preserve the previous default model
  - [ ] Verify plain chat through DRW; normal `pi` retains native session saving and context discovery because those have no equivalent disabling settings
  - [ ] Add and verify the full-process sandbox and protected recovery before enabling execution or write tools
  - [x] Enable read, grep, find, and ls as the default workspace tools
  - [ ] Enable controlled execution/editing after sandbox and recovery verification, then one reviewed plugin at a time
  - [ ] Add canonical rules/skills, sessions, MCP services, memory, jobs, and subagents individually; keep everything unused disabled
  - [ ] Verify each addition against the existing acceptance checks before enabling the next
- [ ] Establish the Pi baseline
  - [ ] Pin a supported Pi release and extension versions; this audit checked v1.5.0, which already includes MCP and codemode
  - [ ] Keep reusable configuration and extensions in dotfiles; keep credentials, sessions, and machine-specific endpoints outside Git
  - [ ] Make installation and symlinks work on the machines where I use the harness
- [ ] Connect the existing model gateway
  - [ ] Configure the DRW Portkey endpoint, Responses API, required provider/metadata headers, and environment-based credentials
  - [ ] Verify real streamed responses, tool calls, reasoning levels, cancellation, usage reporting, and provider errors through the gateway
  - [ ] Carry over model selection and compaction settings using verified model context limits; do not assume gateway compatibility from its name
  - [ ] Support switching between the Claude and OpenAI models I use without losing the active conversation
- [ ] Enforce sandbox boundaries
  - [ ] Choose and verify an OS sandbox, container, or VM boundary for the entire agent process, including extensions, subagents, shell commands, and language servers
  - [ ] Expose only task-required paths; protect unrelated repositories, home directories, SSH material, credentials, host processes, and privileged sockets
  - [ ] Keep original host data read-only and make changes in a disposable workspace or protected overlay; apply changes through a controlled boundary with recovery checkpoints
  - [ ] Route model and MCP access through scoped credentials or a proxy; prevent arbitrary subprocesses from reading reusable secrets
  - [ ] Restrict network access to required services and keep production mutations behind explicit authorization
  - [ ] Fail closed if the sandbox cannot start; never silently retry on the unrestricted host
  - [ ] Verify escape attempts through symlinks, child processes, alternate interpreters, extension code, and filesystem/network access outside the allowed scope
- [ ] Make destructive changes recoverable
  - [ ] Preserve tracked files, untracked files, ignored files, existing uncommitted edits, and files changed since the previous checkpoint
  - [ ] Store recovery data outside the agent's writable boundary so generated commands cannot destroy it
  - [ ] Require a verified recovery checkpoint before applying a deletion, overwrite, truncation, rename-overwrite, or destructive Git operation to persistent data
  - [ ] Provide inspect and restore actions with original paths and metadata; retain deleted files in protected recovery storage instead of permanently deleting them
  - [ ] Block permanent purge by the agent; recovery retention and cleanup must be controlled outside its authority
  - [ ] Cover destruction through Python/Node, shell redirection, find -delete, git clean/reset, and other commands; an rm filter alone is insufficient
  - [ ] Prove restoration of a deleted untracked file and overwritten uncommitted content after both successful runs and crashes
- [ ] Preserve action authorization
  - [ ] Keep the existing rules for explicit push/deploy/restart approval, protected default branches, draft PRs, and no GitHub review-conversation mutations
  - [ ] Expose read-only MCP tools by default and place independent enforcement on writable external tools and credentials
  - [ ] Keep approval decisions bound to the concrete action; do not let skills, repository content, or tool results supply authority
  - [ ] Distinguish enforced controls from instructions; project trust and prompt rules do not constitute a sandbox
- [x] Add cozy-prompt with a Catppuccin toolbar and inset prompt panel; keep regular terminal mode for Neovim scrollback
- [ ] Add focus mode
  - [x] Add src/ai/pi/plugins/minimal-command-menu with an editable slash-command whitelist; preserve skill, argument, and file completion
  - [ ] Add a command and shortcut to toggle focus mode and remember the preference
  - [ ] Hide tool call headers, arguments, streaming output, results, images produced by tools, and subagent tool chatter from the visible transcript
  - [ ] Keep user messages, assistant progress/answers, a compact running/waiting indicator, and required approval requests visible
  - [ ] Report actionable failures concisely without dumping raw tool output
  - [ ] Preserve full tool events and results for model context, local history, debugging, and later inspection; hiding is presentation-only
  - [ ] Allow revealing the complete transcript during or after work, including after resume
  - [ ] Try Pi's global tool-renderer extension API first; verify whether it can remove outer spacing and all tool images, and make a narrow TUI change only if needed
  - [ ] Verify in the actual Neovim Snacks terminal and tmux, including streaming, failures, approval prompts, cancellation, and resumed sessions
- [ ] Preserve worktree and editor integration
  - [ ] Add pi-worktree-resume using the Git root or current directory, native pi --continue, --fresh, and correct exit-status propagation
  - [ ] Point AI_CLI_CMD at the Pi launcher and preserve the existing Snacks terminal toggle
  - [ ] Verify the current @file:line and @file:start-end mappings; translate references if Pi does not resolve their existing syntax correctly
  - [ ] Verify restart, fresh session, subdirectory launch, two separate worktrees, and a missing/moved session directory
- [ ] Reuse existing instructions and skills
  - [x] Symlink GLOBAL.md into ~/.pi/agent/AGENTS.md and verify Pi loads its contents
  - [ ] Verify ancestor/project AGENTS.md and CLAUDE.md discovery
  - [x] Load every skill under ~/dotfiles/src/ai/skills through an explicit directory whitelist and enable skill commands; exclude Pi's default skill discovery directories with !skills/** so new dotfiles skills are included without per-skill entries
  - [ ] Verify skill workflows through Pi, including brainstorm, code-review, debug, postmortem, and applauncher-use
  - [ ] Audit skill assumptions about tool names, delegation, model routing, questions, and local artifacts; adapt only incompatible harness contracts
  - [ ] Keep familiar /brainstorm and /code-review entry points through aliases/templates if desired; Pi's native commands use /skill:name
  - [ ] Verify rule loading stays scoped and debug/postmortem still produce the existing Marimo and anvil artifacts
- [ ] Configure the MCP tools I use
  - [ ] Migrate developer, Slack read-only, Polaris, Grafana, Splunk, and OpenAI documentation servers to Pi's native MCP configuration
  - [ ] Preserve per-tool exposure restrictions, authentication, timeouts, and useful server descriptions
  - [ ] Verify a real read-only call against each required service through the sandbox
  - [ ] Enable native codemode/tool search for bounded output and parallel independent calls; retain ordered errors and results
  - [ ] Add the historical TAPS position-query server only if still needed and accessible
- [ ] Preserve long-running command control
  - [ ] Add or select managed background jobs with stable IDs, bounded incremental output, status, exit codes, cancellation, and process-tree cleanup
  - [ ] Support long tests, benchmarks, local servers, and notebooks while continuing the conversation
  - [ ] Support interactive stdin or PTY sessions where required; verify whether existing Pi facilities cover each case before adding a tool
  - [ ] Bind local development servers to 0.0.0.0 and preserve the existing tmux process-cleanup behavior
  - [ ] Keep jobs and their writable paths inside the sandbox; define what survives harness exit and what must stop
- [ ] Preserve subagent workflows
  - [ ] Start from Pi's bundled subagent example or an existing package; add only the coordination behavior used by the existing skills
  - [ ] Support spawn, task delivery, results, status, follow-up work, wait, interruption, and messages between parent and workers
  - [ ] Preserve explicit model/effort selection where skills require it and inherit the parent's sandbox and authorization limits
  - [ ] Make shared-workspace edit ownership explicit and verify actual tests after delegated edits
  - [ ] Surface concise worker status in focus mode and preserve full worker logs for inspection
- [ ] Preserve cross-session memory
  - [ ] Reuse canonical rules and durable knowledge instead of copying incident recaps into new files
  - [ ] Provide searchable previous-conversation and memory files with source/session references
  - [ ] Add task-relevant memory lookup/injection at session start or before work; keep it bounded and distinguish historical facts from current verification
  - [ ] Preserve explicit-user-request-only memory updates and the existing distinction between shared durable knowledge and local transcript history
  - [ ] Keep old Claude/Codex logs available for read-only search; evaluate Pi import separately rather than assuming lossless conversion
- [ ] Verify native conversation behavior
  - [ ] Exercise queued steering and follow-up messages during active tools; preserve task direction and cancellation
  - [ ] Exercise automatic/manual compaction and resume with important constraints retained
  - [ ] Verify model/thinking selectors, file/image input, context/usage display, and clipboard behavior

## Follow-up work

- [ ] Match terminal preferences
  - [ ] Configure fullscreen mode, Catppuccin Macchiato, useful footer fields, and Escape behavior
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
  - [ ] Keep complete focus mode as an unresolved plugin search/customization task
    - [ ] No reviewed candidate was verified to hide all tool headers/results/images while preserving logs, reveal-on-demand, approvals, and status; collapse shortcuts and hidden-tool declarations are different behaviors
    - [ ] Prototype the global renderer API against the acceptance checks above before choosing a fork or larger UI package
  - [ ] Avoid [pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter) and [pi-mcp-extension](https://github.com/irahardianto/pi-mcp-extension) unless a concrete unsupported transport requires one
    - [ ] Native Pi 1.5.0 already handles the HTTP MCP services I use; additional clients duplicate tool discovery and authentication

- [ ] Approve a concrete plugin combination after verification
  - [ ] Verify published versions, supported Pi/Node versions, licenses, active repository ownership, dependency trees, and lifecycle scripts; pin exact versions or commits
  - [ ] Run each candidate's actual relevant tests against the pinned tree in isolation; README and manifest compatibility do not prove runtime compatibility
  - [ ] Verify the combined load order and tool replacements, especially bash, edit/write, permission hooks, codemode, detached jobs, and subagents
  - [ ] Reject a required safety component if installation/loading fails or the sandbox is unavailable; Pi's ordinary package-loading behavior can warn and continue without a failed package
  - [ ] Prove sandbox failure blocks execution, cross-boundary reads/writes fail, untracked deletions and overwritten uncommitted work restore, and recovery storage cannot be destroyed by the agent
  - [ ] Exercise gateway/MCP reads, delegated edits, long tests, interactive shells, cancellation, compaction/resume, and focus-mode approvals through the actual editor workflow
  - [ ] Record passed checks and remaining gaps in this plan before making the Pi launcher the default

Discovery sources: [Pi package gallery](https://pi.dev/packages) and each repository linked above. Repository inspection identified specific limits; no plugin has been certified safe or compatible end to end. General npm search was unavailable during discovery, so exact publication/install verification remains a checklist item.

## Evidence and verification limits

Audited the current dotfiles, local Claude/Codex history indexes, all 1,193 retained Codex JSONL files, and all three retained Claude project transcripts. Retained logs include imported conversations and worker sessions, so counts below are recorded occurrences rather than unique tasks. Local history indexes contain 18,338 Codex entries and 12,116 Claude entries; some historical features have since changed.

Claude history contains 70 /code-review, 31 /brainstorm, 113 /model, 162 /clear, and 30 /compact entries. Local Claude metadata records 1,436 prompt-queue uses. Codex logs contain 764 spawn_agent calls across 153 files, 36,467 nested write_stdin calls across 510 files, and 584 nonblocking question calls across 108 files. MCP use is substantial: 2,953 Splunk queries, 694 Slack searches, 410 Prometheus queries, and 165 Polaris calls. Image inspection and compaction also appear repeatedly. These demonstrate workflow dependencies; configured Claude LSP plugins alone do not prove agent-side LSP use.

Current Codex configuration uses Portkey with the Responses API, enabled memory, disabled web search, and unrestricted local permissions. Those unrestricted permissions describe the current setup; the requested Pi sandbox is a stronger requirement. Old hook trust records exist, but the referenced global hooks file was absent during this audit.

Pi behavior was checked against source/docs for released v1.5.0 and current documentation. Pi already supports MCP, skills, context files, sessions, steering, compaction, model settings, and codemode. Its security documentation explicitly says project trust does not sandbox tools. Focus mode and end-to-end gateway/sandbox compatibility remain implementation and runtime checks.

Sources: [Pi v1.5.0](https://github.com/earendil-works/pi/releases/tag/v1.5.0), [security](https://github.com/earendil-works/pi/blob/v1.5.0/packages/coding-agent/docs/security.md), [MCP](https://github.com/earendil-works/pi/blob/v1.5.0/packages/coding-agent/docs/mcp.md), [extensions](https://github.com/earendil-works/pi/blob/v1.5.0/packages/coding-agent/docs/extensions.md), [skills](https://github.com/earendil-works/pi/blob/v1.5.0/packages/coding-agent/docs/skills.md), and [official OpenAI documentation](https://learn.chatgpt.com/docs/developer-commands).
