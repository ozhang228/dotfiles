Uses pinned `@anthropic-ai/sandbox-runtime` 0.0.81. Requires Linux, Python 3.11+,
Node with `--use-env-proxy` support, Bubblewrap, socat, ripgrep, Pi, and the DRW
Portkey provider extension.
The dotfiles wrapper directory symlink and Fish PATH setup make normal `pi` calls
sandboxed in new shells; Neovim uses the same isolated entrypoint. Original Pi
executables stay intact. An explicit original binary path can bypass PATH.

One-time setup per machine (installs locked dependencies, loads the Ubuntu
AppArmor profile when needed, and tests isolation):

```sh
make ubuntu # or make manjaro
```

The locked upstream Zod 3 dependency has a [memory-exhaustion advisory](https://osv.dev/vulnerability/GHSA-mrhx-c7xc-m3w5).
SRT receives only launcher-generated policy outside the agent's writable paths;
the published Zod 4 fix is outside this runtime's declared dependency range.

Ubuntu's restricted unprivileged user namespaces can block Bubblewrap with
`loopback: Failed RTM_NEWADDR: Operation not permitted`. If the kernel log shows
AppArmor denying `net_admin` for `bwrap` under `unprivileged_userns`, rerun
the distro setup. Its scoped profile permits user-namespace setup for
`/usr/bin/bwrap` without disabling the system-wide restriction. Setup leaves AppArmor alone when isolation already works; otherwise it reuses
an identical profile and refuses to overwrite a different one.

```sh
python3 ~/dotfiles/src/ai/pi/sandbox/tests/smoke.py
pi --continue
pytest -q ~/dotfiles/src/ai/pi/sandbox
```

Runtime discovery skips the sandbox wrapper and supports DRW prefix installs,
npm package-bin symlinks, and official `releases-v1` managed installs/standalone
Node. Runtime roots and installed tools in `~/.local/bin`, Mason, UV/Pipx/Poetry
environments, Cargo/Rustup, and Bun are mounted read-only when present; tool paths
also work under the disposable sandbox home. Other layouts remain inaccessible.
The provider source comes from the host agent extension
or distribution. No host credential/config directory is mounted.

`settings.json` grants every session access to `~/dotfiles`, `~/anvil`, and
`~/forge`, plus the launch directory when it is a Git repository root. Missing
configured directories are skipped. Edit/Write checkpoint the target file before
a separate worker changes the actual checkout; Neovim and LazyGit see changes
immediately. Bash checkpoints its `writablePaths` directories (default: working
directory); other approved paths remain readable. Use small directory scopes for
large repositories. No approval prompt is required. Git metadata, dotenv files,
private Pi state, shared hardlinks, and sandbox/controller code stay protected.
Pi itself remains read-only. Workers have no network access; supervised servers
and watchers are later stages.

Synthetic `.mcp.json` guards appear as empty read-only files so broad formatter
scans can read them; creating, editing, moving, and deleting those paths stays blocked.

Never request `/tmp`, host home/cache, or tool installations in `writablePaths`.
Use `$TMPDIR` for scripts/reports; UV, npm, and Python bytecode caches point into
disposable scratch. Network-dependent installs and nested sandbox tests remain
blocked; run isolation tests from the host.

`recovery_list` lists checkpoints or their saved files. `recovery_restore` restores
missing selected files and exports existing ones to `.recovered-*` siblings,
so newer Neovim edits are never overwritten. Pre-command tracked, untracked,
ignored, and uncommitted bytes within the writable scope are saved; intermediate changes within a command
are not guaranteed. Checkpoints are per-file captures, not atomic tree snapshots
while another editor is saving. Cancelled commands lose their entire worker tree. Large shell output is truncated;
full-output artifacts are not retained.

Recovery lives outside both sandboxes, under `~/.local/state/pi-sandbox/recovery`.
Content is deduplicated and streamed. Defaults in `recovery.py` are 2 GiB per repo
and 5 GiB total: oldest completed checkpoints are pruned automatically; active
and newest checkpoints remain protected until replacement is durable. Oversized
checkpoints or disk/I/O failures stop new writes. Retention limits cannot repair
an exhausted underlying filesystem.
New blob contents and renames are persisted together with Linux `syncfs` before
the journal exposes the checkpoint, avoiding a separate disk barrier per file.
Kernels older than 5.8 retain per-file flushes for reliable I/O error reporting.

The gateway holds the host DRW key and exposes only fixed model routes and the
scoped controller. Network/Unix-socket restrictions, private namespaces, and
fail-closed preflight remain mandatory. Sessions/cache are separate per project;
only saved model/provider/thinking defaults are merged into the original settings;
sandbox policy overrides stay temporary. Conflicting manual default edits are preserved.
Startup and each command share one fresh credential/Git scan per approved repo.
The host gateway caches successful model catalogues and metadata in
`~/.local/state/pi-sandbox/catalog`, separated by credential, with a 64 MiB limit.
Later launches use the saved catalogue while refreshing in the background;
the first successful fetch needs network access. Inference is never cached.
After smoke passes, check startup,
Ctrl-C, resume, resizing, and scrollback in the host terminal.
