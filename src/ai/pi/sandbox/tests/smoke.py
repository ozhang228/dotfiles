# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import errno
import os
import shutil
import socket
import subprocess
import sys
import tempfile
from pathlib import Path

NAMESPACES = ("user", "mnt", "pid", "net", "ipc", "uts")


def require(condition: bool, message: str):
    if not condition:
        raise RuntimeError(message)


def require_private_proc(*, status: str, pid: int):
    for line in status.splitlines():
        if line.startswith("NSpid:"):
            require(
                [int(value) for value in line.split()[1:]] == [pid],
                "Host PID namespace visible through /proc",
            )
            return
    raise RuntimeError("Missing /proc PID namespace information")


def probe():
    _, mode, host_home, project_name, secret_name, port, *namespace_ids = sys.argv
    project = Path(project_name)
    require(len(namespace_ids) == len(NAMESPACES), "Missing host namespace IDs")
    for namespace, host_id in zip(NAMESPACES, namespace_ids, strict=True):
        require(
            os.readlink(f"/proc/self/ns/{namespace}") != host_id,
            f"Still in host {namespace} namespace",
        )
    require_private_proc(status=Path("/proc/self/status").read_text(), pid=os.getpid())
    require(
        "SSH_AUTH_SOCK" not in os.environ and "USER" not in os.environ,
        "Inherited host environment",
    )
    require(
        os.environ.get("PORTKEY_API_KEY") == "local-broker", "Host credential exposed"
    )
    for hidden in (
        Path(secret_name),
        project / "escape",
        project / ".env",
        project / ".pi/auth.json",
        Path(host_home) / ".pi/agent/auth.json",
        Path("/etc/passwd"),
    ):
        try:
            hidden.read_bytes()
        except (FileNotFoundError, PermissionError):
            pass
        else:
            raise RuntimeError(f"Protected path accessible: {hidden}")
    require((project / "readable").read_text() == "read-only sentinel\n", "Read failed")
    for target in (project / "readable", project / "new-file"):
        try:
            with target.open("ab") as stream:
                stream.write(b"unexpected write\n")
        except OSError as error:
            require(error.errno == errno.EROFS, f"Unexpected write failure: {error}")
        else:
            raise RuntimeError(f"Read-only mount writable: {target}")
    try:
        (project / "readable").unlink()
    except OSError as error:
        require(error.errno == errno.EROFS, f"Unexpected deletion failure: {error}")
    else:
        raise RuntimeError("Original project deletion allowed")
    scratch = Path(os.environ["TMPDIR"]) / f"scratch-{mode}"
    scratch.write_text("private temporary storage\n")
    require(scratch.read_text() == "private temporary storage\n", "Private temp failed")
    cached = Path(os.environ["XDG_CACHE_HOME"]) / f"cache-{mode}"
    cached.write_text("private cache\n")
    require(cached.read_text() == "private cache\n", "Private cache failed")
    config = Path(os.environ["PI_CODING_AGENT_DIR"])
    settings = config / f"settings-{mode}.json"
    settings.write_text("{}")
    lock = config / f"settings-{mode}.json.lock"
    lock.mkdir()
    lock.rmdir()
    require(settings.read_text() == "{}", "Disposable settings write failed")
    require(
        socket.gethostbyname("localhost") == "127.0.0.1", "Proxy host lookup failed"
    )
    with socket.socket() as connection:
        connection.settimeout(1)
        require(
            connection.connect_ex(("127.0.0.1", int(port)))
            in {errno.ECONNREFUSED, errno.ENETUNREACH, errno.EHOSTUNREACH},
            "Host loopback listener reachable",
        )
    try:
        with socket.socket(socket.AF_UNIX) as connection:
            connection.connect(str(project / "socket"))
    except OSError as error:
        require(
            error.errno in {errno.EPERM, errno.EACCES},
            f"Unexpected Unix socket result: {error}",
        )
    else:
        raise RuntimeError("Unix socket filter unavailable")
    if mode == "--probe":
        subprocess.run(
            [sys.executable, "-I", str(Path(__file__)), "--child-probe", *sys.argv[2:]],
            check=True,
            timeout=10,
        )


def smoke_test():
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from launcher import sandbox_environment, sandbox_prefix
    from runtime import find_runtime

    require(sys.platform == "linux", "This smoke test requires Linux")
    node, cli = find_runtime()
    script = Path(__file__).resolve()
    host_ids = tuple(os.readlink(f"/proc/self/ns/{name}") for name in NAMESPACES)
    with (
        tempfile.TemporaryDirectory(prefix="pi-sandbox-smoke-") as directory,
        socket.socket() as listener,
        socket.socket(socket.AF_UNIX) as unix_listener,
    ):
        root = Path(directory)
        project = root / "project"
        project.mkdir()
        readable = project / "readable"
        readable.write_text("read-only sentinel\n")
        protected = root / "secret"
        protected.write_text("protected sentinel\n")
        (project / "escape").symlink_to(protected)
        (project / ".env").write_text("hidden credential")
        (project / ".pi").mkdir()
        (project / ".pi/auth.json").write_text("hidden credential")
        unix_listener.bind(str(project / "socket"))
        unix_listener.listen(1)
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        for name in ("config", "home", "scratch", "state/sessions", "state/cache"):
            (root / name).mkdir(parents=True)
        (root / "cache").symlink_to(root / "state/cache", target_is_directory=True)
        probe_script = root / "config/probe.py"
        shutil.copyfile(script, probe_script)
        prefix = sandbox_prefix(
            node=node,
            cli=cli,
            project=project,
            state=root / "state",
            temporary=root,
            assets=script.parents[3],
        )
        command = [
            *prefix,
            "/usr/bin/python3",
            "-I",
            str(probe_script),
            "--probe",
            str(Path.home()),
            str(project),
            str(protected),
            str(listener.getsockname()[1]),
            *host_ids,
        ]
        result = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            env=sandbox_environment(node=node, temporary=root),
            timeout=30,
        )
        require(readable.read_text() == "read-only sentinel\n", "Host fixture changed")
        require(
            protected.read_text() == "protected sentinel\n",
            "Protected host file changed",
        )
        require(
            result.returncode == 0,
            result.stderr.strip() or f"Sandbox runtime exited {result.returncode}",
        )
    print(
        "PASS: SRT read-only project/deletion protection, secret masking, private temp,"
    )
    print("      namespaces, network/Unix socket restrictions, and child inheritance")


def main():
    try:
        if sys.argv[1:] and sys.argv[1] in {"--probe", "--child-probe"}:
            probe()
        else:
            require(len(sys.argv) == 1, "Usage: python3 tests/smoke.py")
            smoke_test()
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
