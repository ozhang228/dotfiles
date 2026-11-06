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
Node. Only their required runtime roots are mounted read-only; unsupported
layouts fail closed. The provider source comes from the host agent extension
or distribution. No host credential/config directory is mounted.

SRT isolates the complete Pi tree with read-only project/skills, a disposable
writable config copy for Pi's locks and runtime updates, private temp, and
process/network/Unix-socket restrictions. Original configuration stays protected.
`/etc/hosts` is readable so the local sandbox proxy can resolve `localhost`.
A small Bubblewrap shim adds
IPC and hostname isolation. Nested `.pi`/dotenv entries are masked; other secrets
embedded in project files remain readable. SRT's proxy routes only the internal
gateway hostname to the host broker. The broker holds the real DRW key, permits
only fixed catalog/inference/metadata routes, and refuses redirects.
Private sessions/cache use `~/.local/state/pi-sandbox/<project-hash>/`, separate
from normal Pi. Protected editing/checkpoints/apply remain for a later step.
Startup runs dependency and native isolation checks before loading credentials;
missing/degraded isolation never falls back to ordinary Pi. After native smoke
passes, check startup, Ctrl-C, resume, and scrollback in the host terminal.
