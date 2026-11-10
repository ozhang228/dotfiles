# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
from pathlib import Path

from broker import Broker
from controller import Controller, Edit, Worker, Write
from recovery import Recovery
from runtime import agent_dir, find_runtime, provider_source, runtime_roots

RUNTIME_VERSION = "0.0.81"
GATEWAY = "http://pi-gateway.invalid"
PLUGINS = ("compact-tools", "cozy-prompt", "minimal-command-menu")


def assets_root():
    return Path(__file__).resolve().parents[2]


def adapt_provider(path: Path):
    source = path.read_text()
    replacements = {
        '"https://ai.drwcloud.com/v1"': f'"{GATEWAY}/v1"',
        '"https://configs.portkey.ai"': f'"{GATEWAY}/metadata"',
    }
    for original, replacement in replacements.items():
        if source.count(original) != 1:
            raise RuntimeError(
                "Managed Portkey provider changed; sandbox adaptation refused"
            )
        source = source.replace(original, replacement)
    return source


def snapshot_config(config: Path, *, assets: Path, cli: Path, roots=()):
    for source in (
        assets / "pi",
        assets / "rules",
        assets / "skills",
        assets / "_shared",
        assets / "GLOBAL.md",
    ):
        for path in (source, *source.rglob("*")):
            if path.is_symlink() and not any(
                path.resolve().is_relative_to(root) for root in (assets, *roots)
            ):
                raise RuntimeError(
                    "Sandbox config symlinks must stay within approved assets"
                )
    config.mkdir()
    settings = json.loads((assets / "pi/settings.json").read_text())
    if not isinstance(settings, dict):
        raise TypeError("Invalid sandbox settings")
    settings.update(
        {
            "defaultTools": ["read", "grep", "find", "ls"],
            "defaultProjectTrust": "never",
            "transport": "sse",
            "packages": [],
            "extensions": [
                "!**",
                "+builtin:codemode",
                "+builtin:tool-search",
                *[f"+{config}/extensions/{name}/index.ts" for name in PLUGINS],
                f"+{config}/extensions/portkey-provider.ts",
            ],
            "skills": ["!skills/**", str(assets / "skills")],
            "prompts": ["!**"],
            "themes": ["!**", f"+{config}/themes/catppuccin-macchiato.json"],
        }
    )
    settings.pop("sessionDir", None)
    (config / "settings.json").write_text(json.dumps(settings))
    (config / "auth.json").write_text("{}")
    (config / "models.json").write_text('{"providers":{}}')
    shutil.copyfile(assets / "GLOBAL.md", config / "AGENTS.md")
    shutil.copyfile(assets / "pi/keybindings.json", config / "keybindings.json")
    extensions = config / "extensions"
    extensions.mkdir()
    for name in PLUGINS:
        shutil.copytree(assets / "pi/plugins" / name, extensions / name)
    (config / "sandbox").mkdir()
    shutil.copyfile(assets / "pi/sandbox/tools.ts", config / "sandbox/tools.ts")
    (extensions / "portkey-provider.ts").write_text(
        adapt_provider(provider_source(cli))
    )
    shutil.copytree(assets / "pi/themes", config / "themes")


def credential():
    key = os.environ.get("PORTKEY_API_KEY", "").strip()
    if not key:
        auth = json.loads((agent_dir() / "auth.json").read_text())
        drw = auth.get("drw") if isinstance(auth, dict) else None
        if (
            not isinstance(drw, dict)
            or drw.get("type") != "api_key"
            or not isinstance(drw.get("key"), str)
        ):
            raise RuntimeError("A host DRW API key is required for the sandbox gateway")
        key = drw["key"].strip()
        reference = re.fullmatch(
            r"\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))", key
        )
        if reference:
            key = os.environ.get(reference[1] or reference[2], "").strip()
        elif key.startswith(("!", "$")):
            raise RuntimeError(
                "Sandbox gateway accepts literal API keys or simple environment references only"
            )
    if not key or any(character in key for character in "\r\n\x00"):
        raise RuntimeError(
            "A valid host DRW API key is required for the sandbox gateway"
        )
    return key


def sandbox_runtime():
    root = Path.home() / ".local/share/pi-sandbox/runtime/node_modules"
    package = root / "@anthropic-ai/sandbox-runtime"
    try:
        manifest = json.loads((package / "package.json").read_text())
    except OSError as error:
        raise RuntimeError(
            "Install the pinned Pi sandbox runtime; see sandbox/README.md"
        ) from error
    if not isinstance(manifest, dict) or manifest.get("version") != RUNTIME_VERSION:
        raise RuntimeError(f"Pi sandbox requires sandbox-runtime {RUNTIME_VERSION}")
    return root.resolve(), package.resolve()


def check_boundary(command: list[str], *, environment: dict[str, str]):
    result = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
        env=environment,
        timeout=30,
    )
    if result.returncode:
        detail = result.stderr.strip() or f"Sandbox runtime exited {result.returncode}"
        raise RuntimeError(
            f"Sandbox isolation unavailable; Pi was not started\n{detail}"
        )


def private_state(project: Path):
    parent = Path.home() / ".local/state/pi-sandbox"
    root = parent / hashlib.sha256(os.fsencode(project)).hexdigest()[:24]
    for path in (parent, root, root / "sessions", root / "cache"):
        if path.resolve() != path:
            raise RuntimeError("Sandbox state must not contain symlinks")
        path.mkdir(mode=0o700, parents=True, exist_ok=True)
        if path.resolve() != path or path.stat().st_uid != os.getuid():
            raise RuntimeError(
                "Sandbox state must be private and owned by the current user"
            )
        path.chmod(0o700)
    return root


def credential_paths(project: Path):
    for directory, directories, files in os.walk(project, followlinks=False):
        for name in (*directories, *files):
            if name == ".pi" or name == ".env" or name.startswith(".env."):
                path = Path(directory) / name
                if path.is_symlink():
                    raise RuntimeError("Sandbox refuses project .pi or dotenv symlinks")
                yield path
                if name in directories:
                    directories.remove(name)


def approved_repositories(project: Path):
    settings = json.loads(Path(__file__).with_name("settings.json").read_text())
    if not isinstance(settings, dict) or not isinstance(
        settings.get("writableRoots"), list
    ):
        raise ValueError("Sandbox writableRoots must be a list of absolute paths")
    roots = []
    for value in settings["writableRoots"]:
        if not isinstance(value, str) or not value or "\x00" in value:
            raise ValueError("Invalid sandbox repository path")
        path = Path(value).expanduser()
        if not path.is_absolute():
            raise ValueError(
                "Sandbox repository paths must be absolute or start with ~/"
            )
        if path.exists():
            if not path.is_dir():
                raise ValueError("Sandbox repository paths must be directories")
            roots.append(path.resolve())
    if is_repository_root(project):
        roots.append(project)
    unique = tuple(dict.fromkeys(roots))
    return tuple(
        root
        for root in unique
        if not any(root != other and root.is_relative_to(other) for other in unique)
    )


def is_repository_root(project: Path):
    result = subprocess.run(
        ["/usr/bin/git", "-C", str(project), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=False,
        env={"PATH": "/usr/bin:/bin", "HOME": "/nonexistent"},
        timeout=10,
    )
    return result.returncode == 0 and Path(result.stdout.strip()).resolve() == project


def sandbox_prefix(
    *,
    node: Path,
    cli: Path,
    project: Path,
    state: Path,
    temporary: Path,
    assets: Path,
    roots=(),
    write_paths=None,
    writable=False,
    protected=(),
):
    roots = tuple(roots) or (project,)
    write_paths = roots if write_paths is None else tuple(write_paths)
    modules, package = sandbox_runtime()
    sources = (
        *runtime_roots(node=node, cli=cli),
        modules,
        project,
        *roots,
        temporary / "config",
        temporary / "home",
        temporary / "scratch",
        *[assets / name for name in ("rules", "skills", "_shared")],
    )
    host_protected = (agent_dir(), state)
    for source in (*sources[:3], project, *roots):
        if Path.home().resolve().is_relative_to(source) or any(
            path.is_relative_to(source) or source.is_relative_to(state)
            for path in host_protected
        ):
            raise RuntimeError(
                "Pi runtime overlaps host credentials or private sandbox state"
            )

    def literal(path):
        return {"path": str(path), "literal": True}

    policy = {
        "network": {
            "allowedDomains": ["pi-gateway.invalid:80"],
            "deniedDomains": [],
            "strictAllowlist": True,
            "allowAllUnixSockets": False,
            "mitmProxy": {
                "socketPath": str(temporary / "gateway.sock"),
                "domains": ["pi-gateway.invalid"],
            },
        },
        "filesystem": {
            "denyRead": [
                "/",
                "/sys",
                *[literal(path) for root in roots for path in credential_paths(root)],
            ],
            "allowRead": [
                *[
                    literal(Path(path).resolve())
                    for path in ("/usr", "/lib", "/lib64", "/etc/hosts")
                    if Path(path).exists()
                ],
                *map(literal, sources),
            ],
            "allowWrite": list(
                map(
                    literal,
                    (
                        state / "sessions",
                        state / "cache",
                        temporary / "scratch",
                        temporary / "config",
                    ),
                )
            ),
            "denyWrite": list(
                map(literal, protected if writable else (project, *roots))
            ),
        },
        "enableWeakerNestedSandbox": False,
        "allowNestedUserNamespaces": False,
        "bwrapPath": str(Path(__file__).with_name("bwrap").resolve()),
    }
    if writable:
        policy["network"] = {
            "allowedDomains": [],
            "deniedDomains": ["*"],
            "allowAllUnixSockets": False,
        }
        policy["filesystem"]["allowWrite"] = list(
            map(literal, (*write_paths, temporary / "scratch"))
        )
        policy["filesystem"]["allowRead"] = [
            literal(Path(path).resolve())
            for path in ("/usr", "/lib", "/lib64", "/etc/hosts")
            if Path(path).exists()
        ] + list(
            map(
                literal,
                (
                    *runtime_roots(node=node, cli=cli),
                    modules,
                    project,
                    *roots,
                    temporary / "config",
                    temporary / "home",
                    temporary / "scratch",
                ),
            )
        )
    settings = temporary / "sandbox.json"
    settings.write_text(json.dumps(policy))
    return [
        str(node),
        str(package / "dist/cli.js"),
        "--settings",
        str(settings),
        "--",
    ]


def sandbox_environment(*, node: Path, temporary: Path):
    environment = {
        "HOME": str(temporary / "home"),
        "PATH": f"{node.parent}:/usr/bin:/bin",
        "PI_CODING_AGENT_DIR": str(temporary / "config"),
        "PORTKEY_API_KEY": "local-broker",
        "NODE_USE_ENV_PROXY": "1",
        "XDG_CACHE_HOME": str((temporary / "cache").resolve()),
        "TMPDIR": str(temporary / "scratch"),
        # SRT overrides TMPDIR from this variable when filesystem isolation is enabled.
        "CLAUDE_CODE_TMPDIR": str(temporary / "scratch"),
        "LANG": "C.UTF-8",
    }
    for name in ("TERM", "COLORTERM"):
        if name in os.environ:
            environment[name] = os.environ[name]
    return environment


def protected_git_paths(project: Path):
    for directory, directories, files in os.walk(project, followlinks=False):
        if ".git" in (*directories, *files):
            path = Path(directory) / ".git"
            if path.is_symlink():
                raise RuntimeError(
                    "Git metadata symlinks are not supported for writable projects"
                )
            yield path
            if ".git" in directories:
                directories.remove(".git")


def editing_controller(
    *, node: Path, cli: Path, project: Path, state: Path, assets: Path, roots=()
):
    if not roots and not is_repository_root(project):
        return None
    roots = tuple(roots) or (project,)
    controller_sources = (Path(__file__).resolve().parent, assets / "pi/sandbox")
    recoveries = tuple(
        Recovery(
            state.parent / "recovery",
            repo=root,
            protected=[
                *protected_git_paths(root),
                *credential_paths(root),
                *controller_sources,
            ],
        )
        for root in roots
    )

    def run(request, stop, lock_fd):
        with tempfile.TemporaryDirectory(prefix="pi-worker-") as directory:
            temporary = Path(directory)
            (temporary / "config").mkdir()
            (temporary / "home").mkdir()
            for root in roots:
                if root.parent == Path.home():
                    (temporary / "home" / root.name).symlink_to(
                        root, target_is_directory=True
                    )
            (temporary / "scratch").mkdir()
            (temporary / "cache").symlink_to(
                temporary / "scratch", target_is_directory=True
            )
            helper = temporary / "config/worker.mjs"
            shutil.copyfile(Path(__file__).with_name("worker.mjs"), helper)
            selections = {}
            targets = (
                (request.path,)
                if isinstance(request, (Write, Edit))
                else request.writablePaths
            )
            for value in targets:
                target = Path(value)
                root = next(root for root in roots if target.is_relative_to(root))
                selections.setdefault(root, []).append(target.relative_to(root))
            if isinstance(request, (Write, Edit)):
                writable = Path(request.path).parent
                while not writable.exists():
                    writable = writable.parent
                write_paths = (writable,)
            else:
                write_paths = tuple(Path(path) for path in request.writablePaths)
            sandbox_prefix(
                node=node,
                cli=cli,
                project=project,
                state=state,
                temporary=temporary,
                assets=assets,
                roots=roots,
                write_paths=write_paths,
                writable=True,
                protected=[
                    *controller_sources,
                    *[
                        path
                        for store in recoveries
                        for path in (
                            *protected_git_paths(store.repo),
                            *credential_paths(store.repo),
                            *store.shared_paths(paths=selections.get(store.repo, [])),
                        )
                    ],
                ],
            )
            environment = sandbox_environment(node=node, temporary=temporary)
            environment.pop("PORTKEY_API_KEY")
            from runtime import module_root

            native = (
                module_root(cli)
                / "@earendil-works/pi-coding-agent/dist/core/tools/index.js"
            )
            _, package = sandbox_runtime()

            def command(lifeline):
                return [
                    str(node),
                    str(helper),
                    "supervise",
                    str(package / "dist/index.js"),
                    str(temporary / "sandbox.json"),
                    str(lifeline),
                    str(native),
                    str(lock_fd),
                ]

            yield from Worker(command=command, environment=environment, repo=project)(
                request, stop, lock_fd
            )

    return Controller(recoveries[0], run=run, recoveries=recoveries, cwd=project)


def main():
    if sys.platform != "linux":
        raise RuntimeError("Pi sandbox requires Linux and Bubblewrap")
    bubblewrap = shutil.which("bwrap")
    if bubblewrap is None:
        raise RuntimeError("Install Bubblewrap before launching sandboxed Pi")
    project = Path.cwd().resolve()
    home = Path.home().resolve()
    roots = approved_repositories(project)
    protected = (agent_dir(), home / ".pi", home / ".local/state/pi-sandbox")
    if any(
        home.is_relative_to(root)
        or any(
            root.is_relative_to(path) or path.is_relative_to(root) for path in protected
        )
        for root in (project, *roots)
    ):
        raise RuntimeError(
            "Sandbox project must not expose the host home or private Pi state"
        )
    node, cli = find_runtime()
    _, package = sandbox_runtime()
    assets = assets_root()
    state = private_state(project)
    with tempfile.TemporaryDirectory(prefix="pi-sandbox-") as directory:
        temporary = Path(directory)
        if temporary.is_relative_to(project) or state.is_relative_to(project):
            raise RuntimeError(
                "Sandbox project overlaps private gateway or state storage"
            )
        (temporary / "scratch").mkdir()
        (temporary / "home").mkdir()
        for root in roots:
            if root.parent == home:
                (temporary / "home" / root.name).symlink_to(
                    root, target_is_directory=True
                )
        (temporary / "cache").symlink_to(state / "cache", target_is_directory=True)
        snapshot_config(temporary / "config", assets=assets, cli=cli, roots=roots)
        environment = sandbox_environment(node=node, temporary=temporary)
        # Refuse unsupported proxy support or degraded isolation before loading credentials.
        dependency_check = (
            "const {SandboxManager}=await import(process.argv[1]);"
            "const deps=SandboxManager.checkDependencies();"
            "const issues=[...deps.errors,...deps.warnings];"
            "if(!process.allowedNodeEnvironmentFlags.has('--use-env-proxy'))"
            "issues.push('Node needs --use-env-proxy support');"
            "if(issues.length){console.error(issues.join('\\n'));process.exit(1)}"
        )
        check_boundary(
            [
                str(node),
                "--input-type=module",
                "--eval",
                dependency_check,
                (package / "dist/index.js").as_uri(),
            ],
            environment=environment,
        )
        command = sandbox_prefix(
            node=node,
            cli=cli,
            project=project,
            state=state,
            temporary=temporary,
            assets=assets,
            roots=roots,
        )
        check_boundary([*command, "/usr/bin/true"], environment=environment)
        controller = editing_controller(
            node=node, cli=cli, project=project, state=state, assets=assets, roots=roots
        )
        if controller is not None:
            environment["PI_SANDBOX_CONTROL"] = "1"
            settings_path = temporary / "config/settings.json"
            settings = json.loads(settings_path.read_text())
            settings["defaultTools"] = [
                "read",
                "grep",
                "find",
                "ls",
                "edit",
                "write",
                "bash",
                "recovery_list",
                "recovery_restore",
            ]
            settings_path.write_text(json.dumps(settings))
        with Broker(
            temporary / "gateway.sock", key=credential(), controller=controller
        ) as broker:
            thread = threading.Thread(target=broker.serve_forever, daemon=True)
            thread.start()
            try:
                status = subprocess.run(
                    [
                        *command,
                        str(node),
                        str(cli),
                        *sys.argv[1:],
                        "--no-mcp",
                        "--no-approve",
                        "--session-dir",
                        str(state / "sessions"),
                    ],
                    check=False,
                    env=environment,
                ).returncode
            finally:
                if controller is not None:
                    controller.close()
                broker.shutdown()
                thread.join()
    return status if status >= 0 else 128 - status


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except RuntimeError as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
    except (OSError, TypeError, ValueError, subprocess.SubprocessError):
        print(
            "Pi sandbox could not start safely; no unrestricted fallback",
            file=sys.stderr,
        )
        sys.exit(1)
