import json
import os
import re
import shlex
import shutil
from pathlib import Path

PACKAGE = "@earendil-works/pi-coding-agent"


def agent_dir():
    return (
        Path(os.environ.get("PI_CODING_AGENT_DIR", "~/.pi/agent"))
        .expanduser()
        .resolve()
    )


def is_executable(path: Path):
    return path.is_file() and os.access(path, os.X_OK)


def module_root(cli: Path):
    for parent in cli.parents:
        if parent.name == "node_modules":
            package = parent / PACKAGE
            if cli.is_relative_to(package):
                parsed = json.loads((package / "package.json").read_text())
                if isinstance(parsed, dict) and parsed.get("name") == PACKAGE:
                    return parent
    raise RuntimeError("Unsupported Pi package layout")


def node_interpreter(script: Path, *, preferred: Path | None = None):
    with script.open() as stream:
        shebang = stream.readline(512).strip()
    words = shlex.split(shebang.removeprefix("#!")) if shebang.startswith("#!") else []
    if words in (["/usr/bin/env", "node"], ["/usr/bin/env", "-S", "node"]):
        candidate = (
            preferred
            if preferred is not None and is_executable(preferred)
            else shutil.which("node")
        )
        if candidate is not None and is_executable(Path(candidate)):
            return Path(candidate).resolve()
    elif (
        len(words) == 1
        and Path(words[0]).is_absolute()
        and Path(words[0]).name in {"node", "nodejs"}
    ):
        candidate = Path(words[0])
        if is_executable(candidate):
            return candidate.resolve()
    raise RuntimeError(
        "Pi requires a supported Node shebang and an installed Node interpreter"
    )


def managed_runtime(entrypoint: Path):
    install = entrypoint.parent.parent / "install"
    marker = install / "managed-install.json"
    if not marker.is_file():
        return None
    parsed = json.loads(marker.read_text())
    if not isinstance(parsed, dict) or any(
        parsed.get(key) != value
        for key, value in {
            "kind": "pi-managed-install",
            "schemaVersion": 1,
            "layout": "releases-v1",
        }.items()
    ):
        raise RuntimeError("Unsupported managed Pi install marker")
    version = (install / "current-version").read_text().strip()
    if version in {".", ".."} or not re.fullmatch(
        r"[A-Za-z0-9][A-Za-z0-9._+-]*", version
    ):
        raise RuntimeError("Invalid managed Pi release version")
    modules = install / "releases" / version / "node_modules"
    cli = (modules / ".bin/pi").resolve(strict=True)
    if not cli.is_relative_to(modules.resolve()) or not is_executable(cli):
        raise RuntimeError("Managed Pi release executable is invalid")
    module_root(cli)
    data = Path(os.environ.get("XDG_DATA_HOME", "~/.local/share")).expanduser()
    node = node_interpreter(cli, preferred=data / "pi-node/current/bin/node")
    return node, cli


def find_runtime():
    wrapper = Path(__file__).with_name("bin") / "pi"
    candidates = [
        Path(directory or os.getcwd()) / "pi"
        for directory in os.environ.get("PATH", os.defpath).split(os.pathsep)
    ]
    candidates.append(agent_dir() / "bin/pi")
    seen = {wrapper.resolve()}
    for candidate in candidates:
        if not is_executable(candidate):
            continue
        executable = candidate.resolve()
        if executable in seen:
            continue
        seen.add(executable)
        managed = managed_runtime(executable)
        if managed is not None:
            return managed
        # DRW's Node wrapper is bypassed; its prefix and shebang identify the runtime.
        distribution = (
            executable.parent.parent
            / "lib/pi/lib/node_modules"
            / PACKAGE
            / "dist/bundle/cli.js"
        )
        cli = distribution.resolve() if distribution.is_file() else executable
        module_root(cli)
        return node_interpreter(executable), cli
    raise RuntimeError(
        "No underlying Pi installation found; sandbox wrapper will not recurse"
    )


def provider_source(cli: Path):
    configured = agent_dir() / "extensions/portkey-provider.ts"
    distribution = module_root(cli).parent.parent / "extensions/portkey-provider.ts"
    for source in (configured, distribution):
        if source.is_file():
            return source.resolve()
    raise RuntimeError(
        "Configure the DRW Portkey provider extension before using sandboxed Pi"
    )


def runtime_roots(*, node: Path, cli: Path):
    node_root = node.parent.parent
    if (
        not (node_root / "include/node").is_dir()
        and not (node_root / "lib/node_modules").is_dir()
    ):
        node_root = node
    return node_root, module_root(cli)
