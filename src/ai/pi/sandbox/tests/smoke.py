# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import errno
import os
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import threading
import time
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
    tool_config = Path(os.environ["XDG_CONFIG_HOME"])
    tool_config.mkdir(parents=True, exist_ok=True)
    (tool_config / "probe").write_text("private tool configuration\n")
    require(
        tool_config.is_relative_to(Path(os.environ["TMPDIR"])),
        "Tool config escaped scratch",
    )
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


def editing_smoke():
    from controller import parse_request
    from launcher import editing_controller
    from runtime import find_runtime

    node, cli = find_runtime()
    with tempfile.TemporaryDirectory(prefix="pi-edit-smoke-") as directory:
        root = Path(directory)
        project = root / "repo"
        project.mkdir()
        subprocess.run(["/usr/bin/git", "init", "-q", str(project)], check=True)
        state = root / "private/project"
        state.mkdir(parents=True)
        outside = root / "outside"
        outside.write_text("outside sentinel")
        (project / "escape").symlink_to(outside)
        (project / "original").write_text("uncommitted original")
        (project / ".env").write_text("protected dotenv")
        assets = project / "protected-ai"
        for name in ("rules", "skills", "_shared"):
            (assets / name).mkdir(parents=True)
        (assets / "pi/sandbox").mkdir(parents=True)
        (assets / "pi/sandbox/controller.py").write_text("protected controller")
        controller = editing_controller(
            node=node, cli=cli, project=project, state=state, assets=assets
        )
        require(controller is not None, "No editable controller")

        def execute(tool, args):
            return list(
                controller.execute(
                    parse_request({"tool": tool, "args": args}), threading.Event()
                )
            )

        execute("write", {"path": "created", "content": "visible checkout change"})
        require(
            (project / "created").read_text() == "visible checkout change",
            "Native write failed",
        )
        execute(
            "edit",
            {
                "path": "created",
                "edits": [{"oldText": "visible", "newText": "immediate"}],
            },
        )
        require(
            (project / "created").read_text() == "immediate checkout change",
            "Native edit failed",
        )
        execute("bash", {"command": "printf damaged > original; rm created"})
        require((project / "original").read_text() == "damaged", "Native bash failed")
        checkpoint = controller.recovery.list()[0]["checkpoint"]
        paths = controller.recovery.restore(checkpoint, ["original", "created"])
        require(
            (project / paths[0]).read_text() == "uncommitted original",
            "Original recovery failed",
        )
        require(
            (project / "created").read_text() == "immediate checkout change",
            "Deleted file recovery failed",
        )
        command = f"printf bad > {outside}; printf bad > escape; printf bad > .git/config; printf bad > .git/new; printf bad > protected-ai/pi/sandbox/controller.py; printf bad > .env; printf bad > {state.parent / 'recovery/lock'}; true"
        git_config = (project / ".git/config").read_bytes()
        execute("bash", {"command": command})
        require(outside.read_text() == "outside sentinel", "Outside scope changed")
        require((project / ".env").read_text() == "protected dotenv", "Dotenv changed")
        require(
            (project / ".git/config").read_bytes() == git_config, "Git metadata changed"
        )
        require(not (project / ".git/new").exists(), "Git metadata creation allowed")
        require(
            (assets / "pi/sandbox/controller.py").read_text() == "protected controller",
            "Controller assets changed",
        )
        large_output = execute(
            "bash", {"command": "head -c 100000 /dev/zero | tr '\\0' x"}
        )[-1]["result"]
        require(
            "fullOutputPath" not in large_output.get("details", {}),
            "Unavailable output path advertised",
        )
        require(
            "full_output_path" not in large_output.get("structuredContent", {}),
            "Unavailable structured output path advertised",
        )
        require(
            "full output is not retained" in large_output["content"][0]["text"],
            "Truncated output limitation missing",
        )
        for interruption in ("cancel", "supervisor-crash"):
            (project / "ticks").unlink(missing_ok=True)
            stop = threading.Event()
            errors = []
            original_before = (project / "original").read_bytes()

            def detached_operation():
                try:
                    list(
                        controller.execute(
                            parse_request(
                                {
                                    "tool": "bash",
                                    "args": {
                                        "command": 'setsid sh -c "while :; do echo tick >> ticks; sleep 0.05; done" & wait',
                                        "timeout": 30,
                                    },
                                }
                            ),
                            stop,
                        )
                    )
                except RuntimeError as error:
                    errors.append(error)

            thread = threading.Thread(target=detached_operation)
            thread.start()
            try:
                deadline = time.monotonic() + 15
                while not (project / "ticks").exists() and time.monotonic() < deadline:
                    time.sleep(0.05)
                require((project / "ticks").exists(), "Detached worker never started")
                match interruption:
                    case "cancel":
                        stop.set()
                    case "supervisor-crash":
                        children = Path(f"/proc/self/task/{thread.native_id}/children")
                        supervisor = next(
                            int(pid)
                            for pid in children.read_text().split()
                            if b"supervise"
                            in Path(f"/proc/{pid}/cmdline").read_bytes().split(b"\0")
                        )
                        os.kill(supervisor, signal.SIGKILL)
                    case _:
                        raise RuntimeError("Unknown interruption")
                thread.join(timeout=10)
                require(
                    not thread.is_alive() and bool(errors),
                    f"Worker did not exit after {interruption}",
                )
                size = (project / "ticks").stat().st_size
                time.sleep(0.3)
                require(
                    (project / "ticks").stat().st_size == size,
                    f"Write-capable child survived {interruption}",
                )
                checkpoint = controller.recovery.list()[0]
                require(checkpoint["status"] == "interrupted", "Checkpoint lost")
                resumed = threading.Event()
                deadline = threading.Timer(10, resumed.set)
                deadline.start()
                try:
                    restored = list(
                        controller.execute(
                            parse_request(
                                {
                                    "tool": "recovery_restore",
                                    "args": {
                                        "checkpoint": checkpoint["checkpoint"],
                                        "paths": ["original"],
                                    },
                                }
                            ),
                            resumed,
                        )
                    )[0]["result"]["paths"]
                finally:
                    deadline.cancel()
                require(
                    (project / restored[0]).read_bytes() == original_before,
                    "Interrupted checkpoint recovery failed",
                )
            finally:
                stop.set()
                thread.join(timeout=10)

        execute("write", {"path": "recover-me", "content": "precious bytes"})
        execute("bash", {"command": "rm recover-me; mkfifo pipe"})
        checkpoint = controller.recovery.list()[0]["checkpoint"]
        restored = execute(
            "recovery_restore",
            {"checkpoint": checkpoint, "paths": ["recover-me"]},
        )[0]["result"]["paths"]
        require(
            (project / restored[0]).read_text() == "precious bytes",
            "Special file blocked recovery",
        )
        require((project / "pipe").exists(), "Recovery changed unrelated special file")
        controller.close()
    print(
        "PASS: native Edit/Write/Bash, protected Git/credentials/outside paths, special-file recovery, and worker cancellation/crash recovery"
    )


def main():
    try:
        if sys.argv[1:] and sys.argv[1] in {"--probe", "--child-probe"}:
            probe()
        else:
            require(len(sys.argv) == 1, "Usage: python3 tests/smoke.py")
            smoke_test()
            editing_smoke()
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
