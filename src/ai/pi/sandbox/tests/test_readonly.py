import json
import shlex
import socket
import sys
import tempfile
import threading
import time
from pathlib import Path
from unittest.mock import patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from controller import parse_request
from launcher import assets_root, editing_controller
from runtime import find_runtime


def test_installed_tools_run_readonly_with_scratch_caches_and_home_aliases():
    node, cli = find_runtime()
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        launch = root / "launch"
        launch.mkdir()
        (launch / ".env").write_text("private launch credentials")
        binaries = root / "tools/bin"
        binaries.mkdir(parents=True)
        uv = binaries / "uv"
        uv.write_text('#!/bin/sh\nprintf "installed uv\\n"\n')
        uv.chmod(0o755)
        mason = root / "tools/mason"
        (mason / "bin").mkdir(parents=True)
        (mason / "packages").mkdir()
        formatter = mason / "packages/oxfmt"
        formatter.write_text('#!/bin/sh\nprintf "installed formatter\\n"\n')
        formatter.chmod(0o755)
        (mason / "bin/oxfmt").symlink_to(formatter)
        cache = root / "host-cache"
        cache.mkdir()
        (cache / "private").write_text("host cache remains private")
        (binaries / "escape").symlink_to(cache / "private")
        tools = {
            Path(".local/bin"): binaries,
            Path(".local/share/nvim/mason"): mason,
        }
        script = f"""import os, pathlib, subprocess
assert subprocess.check_output(["uv"], text=True) == "installed uv\\n"
formatter = pathlib.Path.home() / ".local/share/nvim/mason/bin/oxfmt"
assert subprocess.check_output([str(formatter)], text=True) == "installed formatter\\n"
for name in ["UV_CACHE_DIR", "npm_config_cache", "PYTHONPYCACHEPREFIX", "CARGO_HOME"]:
    path = pathlib.Path(os.environ[name])
    assert path.is_relative_to(os.environ["TMPDIR"])
    path.mkdir(parents=True, exist_ok=True)
    (path / "scratch").write_text("disposable")
for action in [lambda: pathlib.Path({str(uv)!r}).write_text("damaged"),
               lambda: pathlib.Path({str(launch / ".env")!r}).read_text(),
               lambda: pathlib.Path({str(binaries / "escape")!r}).read_text()]:
    try: action()
    except OSError: pass
    else: raise RuntimeError("tool mount escaped")
print("tools and scratch verified")
"""
        controller = editing_controller(
            node=node,
            cli=cli,
            project=launch,
            state=root / "private/session",
            assets=assets_root(),
            roots=(repo,),
        )
        assert controller is not None
        try:
            with patch("launcher.installed_tools", return_value=tools):
                messages = list(
                    controller.execute(
                        parse_request(
                            {
                                "tool": "readonly_bash",
                                "args": {
                                    "command": f"python3 -c {shlex.quote(script)}",
                                    "runId": "installed-tools",
                                },
                            }
                        ),
                        threading.Event(),
                    )
                )
            assert "tools and scratch verified" in json.dumps(messages)
            assert uv.read_text() == '#!/bin/sh\nprintf "installed uv\\n"\n'
        finally:
            controller.close()


def test_readonly_shell_uses_scratch_and_rejects_host_capabilities():
    node, cli = find_runtime()
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        sentinel = repo / "sentinel"
        sentinel.write_text("original sentinel")
        (repo / ".env").write_text("private credential")
        (repo / "escape").symlink_to(sentinel)
        controller = editing_controller(
            node=node,
            cli=cli,
            project=repo,
            state=root / "private/session",
            assets=assets_root(),
            roots=(repo,),
        )
        assert controller is not None
        script = """import os, pathlib, socket
scratch = pathlib.Path(os.environ["TMPDIR"])
(scratch / "reproducer.py").write_text("print(6 * 7)")
exec((scratch / "reproducer.py").read_text())
for action in [lambda: pathlib.Path("created").write_text("bad"),
               lambda: pathlib.Path("sentinel").write_text("bad"),
               lambda: pathlib.Path("sentinel").unlink(),
               lambda: pathlib.Path("escape").write_text("bad"),
               lambda: pathlib.Path(".env").read_text(),
               lambda: socket.socket(socket.AF_UNIX).connect("gateway.sock")]:
    try: action()
    except OSError: pass
    else: raise RuntimeError("host capability escaped")
assert "PORTKEY_API_KEY" not in os.environ
with socket.socket() as connection:
    connection.settimeout(0.5)
    assert connection.connect_ex(("1.1.1.1", 443)) != 0
print("readonly verified")
"""
        gateway = socket.socket(socket.AF_UNIX)
        gateway.bind(str(repo / "gateway.sock"))
        gateway.listen()
        request = parse_request(
            {
                "tool": "readonly_bash",
                "args": {
                    "command": f"python3 -c {shlex.quote(script)}",
                    "runId": "isolation-test",
                },
            }
        )
        messages = list(controller.execute(request, threading.Event()))
        assert "42\nreadonly verified" in json.dumps(messages).replace("\\n", "\n")
        assert sentinel.read_text() == "original sentinel"
        assert not (repo / "created").exists()
        assert controller.recovery.list() == []
        with pytest.raises(ValueError, match="writablePaths"):
            parse_request(
                {
                    "tool": "readonly_bash",
                    "args": {
                        "command": "true",
                        "runId": "bad-grant",
                        "writablePaths": [str(repo)],
                    },
                }
            )
        controller.close()
        gateway.close()


def test_readonly_cancel_waits_for_descendants_and_removes_scratch():
    node, cli = find_runtime()
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        controller = editing_controller(
            node=node,
            cli=cli,
            project=repo,
            state=root / "private/session",
            assets=assets_root(),
            roots=(repo,),
        )
        assert controller is not None
        messages = []
        failures = []
        started = threading.Event()
        command = 'echo "$TMPDIR"; (while true; do echo beat >> "$TMPDIR/heartbeat"; sleep .05; done) & wait'

        def run():
            try:
                for message in controller.execute(
                    parse_request(
                        {
                            "tool": "readonly_bash",
                            "args": {
                                "command": command,
                                "runId": "heartbeat-test",
                            },
                        }
                    ),
                    threading.Event(),
                ):
                    messages.append(message)
                    if message["result"].get("content"):
                        started.set()
            except RuntimeError as error:
                failures.append(str(error))

        thread = threading.Thread(target=run)
        thread.start()
        try:
            assert started.wait(15), "native command did not start"
            output = next(
                message["result"]["content"][0]["text"]
                for message in messages
                if message["result"].get("content")
            )
            scratch = Path(output.strip())
            deadline = time.monotonic() + 5
            while not (scratch / "heartbeat").exists() and time.monotonic() < deadline:
                time.sleep(0.05)
            assert (scratch / "heartbeat").exists()
            # Saturating retained admissions must still stop an existing command.
            for run_id in [
                "cancel-before-start",
                *[f"cancelled-{index}" for index in range(1023)],
            ]:
                list(
                    controller.execute(
                        parse_request(
                            {
                                "tool": "readonly_cancel",
                                "args": {"runId": run_id},
                            }
                        ),
                        threading.Event(),
                    )
                )
            list(
                controller.execute(
                    parse_request(
                        {
                            "tool": "readonly_cancel",
                            "args": {
                                "runId": "heartbeat-test",
                            },
                        }
                    ),
                    threading.Event(),
                )
            )
            thread.join(5)
            assert not thread.is_alive()
            assert failures and "cancelled" in failures[0]
            assert not scratch.exists()
            time.sleep(0.15)
            assert not scratch.exists(), (
                "a descendant recreated scratch after cancellation"
            )
            # Cancellation won admission; the delayed original must never start.
            with pytest.raises(RuntimeError, match="cancelled"):
                list(
                    controller.execute(
                        parse_request(
                            {
                                "tool": "readonly_bash",
                                "args": {
                                    "command": "echo must-not-start",
                                    "runId": "cancel-before-start",
                                },
                            }
                        ),
                        threading.Event(),
                    )
                )
            with pytest.raises(RuntimeError, match="budget exhausted"):
                list(
                    controller.execute(
                        parse_request(
                            {
                                "tool": "readonly_bash",
                                "args": {
                                    "command": "echo must-not-start",
                                    "runId": "fresh-at-capacity",
                                },
                            }
                        ),
                        threading.Event(),
                    )
                )
        finally:
            controller.close()
            thread.join(5)
