import sys
import tempfile
import threading
from collections.abc import Mapping
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from controller import Controller, parse_request
from recovery import Recovery


def test_checkpoint_failure_prevents_worker_and_foreign_paths_are_rejected():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        (repo / "file").write_text("protected content")
        calls = []

        def run(request, stop, lock_fd):
            calls.append(request)
            (repo / "file").write_text("damaged")
            yield {"type": "result", "result": {"content": []}}

        controller = Controller(
            Recovery(root / "private", repo=repo, repo_limit=10, total_limit=10),
            run=run,
        )
        with pytest.raises(RuntimeError, match="limit"):
            list(
                controller.execute(
                    parse_request({"tool": "bash", "args": {"command": "rm file"}}),
                    threading.Event(),
                )
            )
        assert calls == []
        assert (repo / "file").read_text() == "protected content"
        with pytest.raises(ValueError, match="relative"):
            parse_request(
                {"tool": "write", "args": {"path": "../outside", "content": "bad"}}
            )


def test_failed_worker_retains_checkpoint_and_recovery_exports_host_conflict():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        (repo / "file").write_text("original")

        def run(request, stop, lock_fd):
            (repo / "file").write_text("partial damage")
            raise RuntimeError("worker interrupted")
            yield

        controller = Controller(Recovery(root / "private", repo=repo), run=run)
        with pytest.raises(RuntimeError, match="interrupted"):
            list(
                controller.execute(
                    parse_request({"tool": "bash", "args": {"command": "false"}}),
                    threading.Event(),
                )
            )
        checkpoint = controller.recovery.list()[0]
        assert checkpoint["status"] == "interrupted"
        (repo / "file").write_text("new Neovim edit")
        results = list(
            controller.execute(
                parse_request(
                    {
                        "tool": "recovery_restore",
                        "args": {
                            "checkpoint": checkpoint["checkpoint"],
                            "paths": ["file"],
                        },
                    }
                ),
                threading.Event(),
            )
        )
        result = results[0]
        recovered = result["result"]["paths"][0]
        assert (repo / recovered).read_text() == "original"
        assert (repo / "file").read_text() == "new Neovim edit"


def test_shared_repositories_support_absolute_paths_and_recovery_without_escape():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        launch = root / "launch"
        launch.mkdir()
        repos = tuple(root / name for name in ("dotfiles", "anvil", "forge"))
        for repo in repos:
            repo.mkdir()
            (repo / "file").write_text(repo.name)
        stores = tuple(Recovery(root / "private", repo=repo) for repo in repos)
        (repos[1] / "large-cache").write_bytes(b"cache" * 10000)

        def run(request, stop, lock_fd):
            if hasattr(request, "path"):
                Path(request.path).write_text(request.content)
            else:
                for repo in repos:
                    (repo / "file").unlink()
            yield {"type": "result", "result": {"content": []}}

        controller = Controller(stores[0], run=run, recoveries=stores, cwd=launch)
        (repos[0] / "knowledge").symlink_to(repos[1] / "file")
        list(
            controller.execute(
                parse_request(
                    {
                        "tool": "write",
                        "args": {
                            "path": str(repos[0] / "knowledge"),
                            "content": "updated knowledge",
                        },
                    }
                ),
                threading.Event(),
            )
        )
        assert (repos[1] / "file").read_text() == "updated knowledge"
        assert stores[0].list() == []
        assert len(stores[1].list()) == 1
        assert [
            entry["path"]
            for entry in stores[1].paths(stores[1].list()[0]["checkpoint"])
        ] == ["file"]

        (repos[0] / "escape").symlink_to(launch / "outside")
        for target in (
            launch / "outside",
            repos[0] / "escape",
            repos[2] / ".git/config",
        ):
            with pytest.raises(ValueError, match="approved|protected"):
                list(
                    controller.execute(
                        parse_request(
                            {
                                "tool": "write",
                                "args": {
                                    "path": str(target),
                                    "content": "bad",
                                },
                            }
                        ),
                        threading.Event(),
                    )
                )
        assert not (launch / "outside").exists()

        list(
            controller.execute(
                parse_request(
                    {
                        "tool": "bash",
                        "args": {
                            "command": "delete files in all approved repositories",
                            "writablePaths": [str(repo) for repo in repos],
                        },
                    }
                ),
                threading.Event(),
            )
        )
        history = list(
            controller.execute(
                parse_request({"tool": "recovery_list", "args": {}}), threading.Event()
            )
        )[0]["result"]["entries"]
        assert {entry["repo"] for entry in history} == {str(repo) for repo in repos}
        for repo in repos:
            checkpoint = next(
                entry["checkpoint"] for entry in history if entry["repo"] == str(repo)
            )
            list(
                controller.execute(
                    parse_request(
                        {
                            "tool": "recovery_restore",
                            "args": {
                                "checkpoint": checkpoint,
                                "paths": ["file"],
                            },
                        }
                    ),
                    threading.Event(),
                )
            )
        assert [(repo / "file").read_text() for repo in repos] == [
            "dotfiles",
            "updated knowledge",
            "forge",
        ]


def test_failed_shared_checkpoint_blocks_bash_before_any_repository_changes():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repos = (root / "first", root / "second")
        for repo in repos:
            repo.mkdir()
            (repo / "file").write_text("original")
        stores = (
            Recovery(root / "private", repo=repos[0]),
            Recovery(root / "private", repo=repos[1], repo_limit=10),
        )
        calls = []

        def run(request, stop, lock_fd):
            calls.append(request)
            yield {"type": "result", "result": {"content": []}}

        controller = Controller(stores[0], run=run, recoveries=stores)
        with pytest.raises(RuntimeError, match="limit"):
            list(
                controller.execute(
                    parse_request(
                        {
                            "tool": "bash",
                            "args": {
                                "command": "rm file",
                                "writablePaths": [str(repo) for repo in repos],
                            },
                        }
                    ),
                    threading.Event(),
                )
            )
        assert calls == []
        assert stores[0].list()[0]["status"] == "interrupted"
        assert [(repo / "file").read_text() for repo in repos] == [
            "original",
            "original",
        ]


def test_native_pi_direct_and_codemode_tools_edit_existing_checkout():
    import contextlib
    import http.client
    import json
    import subprocess
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

    from broker import Broker
    from launcher import (
        approved_repositories,
        assets_root,
        editing_controller,
        sandbox_environment,
        sandbox_prefix,
        snapshot_config,
    )
    from runtime import find_runtime

    calls = []
    native_calls = []

    class Model(BaseHTTPRequestHandler):
        def do_GET(self):
            payload = (
                {"data": [{"id": "@azure/gpt-5.6-sol"}]}
                if self.path == "/v1/models"
                else {}
            )
            body = json.dumps(payload).encode()
            self.send_response(200)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self):
            calls.append(
                json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            )
            index = len(calls) - 1
            if index < len(native_calls):
                name, args = native_calls[index]
                item = {
                    "id": f"fc_{index}",
                    "type": "function_call",
                    "call_id": f"call_{index}",
                    "name": name,
                    "arguments": json.dumps(args),
                    "status": "completed",
                }
                added = {**item, "arguments": "", "status": "in_progress"}
                delta = {
                    "type": "response.function_call_arguments.delta",
                    "output_index": 0,
                    "delta": item["arguments"],
                }
            else:
                item = {
                    "id": "msg_done",
                    "type": "message",
                    "role": "assistant",
                    "status": "completed",
                    "content": [
                        {
                            "type": "output_text",
                            "text": "editing complete",
                            "annotations": [],
                        }
                    ],
                }
                added = {**item, "content": [], "status": "in_progress"}
                delta = {
                    "type": "response.output_text.delta",
                    "output_index": 0,
                    "content_index": 0,
                    "delta": "editing complete",
                }
            response = {
                "id": f"resp_{index}",
                "object": "response",
                "created_at": 1,
                "model": "gpt-5.6-sol",
                "status": "completed",
                "output": [item],
                "usage": {"input_tokens": 1, "output_tokens": 1, "total_tokens": 2},
            }
            events: list[Mapping[str, object]] = [
                {
                    "type": "response.created",
                    "response": {**response, "status": "in_progress", "output": []},
                },
                {
                    "type": "response.output_item.added",
                    "output_index": 0,
                    "item": added,
                },
            ]
            if item["type"] == "message":
                events.append(
                    {
                        "type": "response.content_part.added",
                        "output_index": 0,
                        "content_index": 0,
                        "part": {"type": "output_text", "text": "", "annotations": []},
                    }
                )
            events.extend(
                [
                    delta,
                    {
                        "type": "response.output_item.done",
                        "output_index": 0,
                        "item": item,
                    },
                    {"type": "response.completed", "response": response},
                ]
            )
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.end_headers()
            for event in events:
                self.wfile.write(f"data: {json.dumps(event)}\n\n".encode())
                self.wfile.flush()

        def log_message(self, format, *args):
            pass

    @contextlib.contextmanager
    def serve(server):
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            yield server
        finally:
            server.shutdown()
            server.server_close()
            thread.join()

    node, cli = find_runtime()
    with (
        tempfile.TemporaryDirectory(prefix="pi-native-tools-") as directory,
        serve(ThreadingHTTPServer(("0.0.0.0", 0), Model)) as model,
    ):
        root = Path(directory)
        project = root / "repo"
        project.mkdir()
        (project / ".zprofile").touch()
        zprofile_inode = (project / ".zprofile").stat().st_ino
        (project / ".claude").mkdir()
        (project / ".claude/settings.local.json").write_bytes(b'{"allowed":true}')
        shared = tuple(root / name for name in ("dotfiles", "anvil", "forge"))
        for repo in shared:
            repo.mkdir()
            (repo / "file").write_text(repo.name)
        (shared[0] / "knowledge").symlink_to(shared[1] / "file")
        roots = (project, *shared)
        native_calls = [
            (
                "codemode",
                {
                    "code": "text(await tools.write({path:"
                    + json.dumps(str(shared[0] / "knowledge"))
                    + ',content:"private knowledge",summary:"write shared knowledge"})); text(await tools.edit({path:'
                    + json.dumps(str(shared[2] / "file"))
                    + ',edits:[{oldText:"forge",newText:"edited forge"}],summary:"edit shared source"})); text(await tools.read({path:'
                    + json.dumps(str(shared[1] / "file"))
                    + ',summary:"read shared knowledge"})); text(await tools.bash({command:'
                    + json.dumps(
                        f"printf denied > {project / 'uncheckpointed'}; printf shared > {shared[0] / 'file'}; rm {shared[2] / 'file'}"
                    )
                    + ",writablePaths:"
                    + json.dumps([str(repo) for repo in shared])
                    + ',summary:"change shared repositories"}));'
                },
            ),
            (
                "write",
                {
                    "path": str(project / "visible.txt"),
                    "content": "before",
                    "summary": "create visible file",
                },
            ),
            (
                "codemode",
                {
                    "code": "text(await tools.edit({path:"
                    + json.dumps(str(project / "visible.txt"))
                    + ',edits:[{oldText:"before",newText:"after"}],summary:"update visible file"})); text(await tools.bash({command:"printf shell > shell.txt",summary:"create shell file"})); text(await tools.recovery_list({}));'
                },
            ),
            (
                "write",
                {
                    "path": str(root / "outside.txt"),
                    "content": "denied",
                    "summary": "outside scope",
                },
            ),
        ]
        subprocess.run(["/usr/bin/git", "init", "-q", str(project)], check=True)
        cached = root / "cached-package"
        cached.write_text("package")
        (project / ".venv").mkdir()
        (project / ".venv/package.py").hardlink_to(cached)
        state = root / "private/project"
        for name in ("sessions", "cache"):
            (state / name).mkdir(parents=True)
        temporary = root / "temporary"
        for name in ("home", "scratch"):
            (temporary / name).mkdir(parents=True)
        (temporary / "cache").symlink_to(state / "cache", target_is_directory=True)
        snapshot_config(
            temporary / "config",
            assets=assets_root(),
            cli=cli,
            roots=approved_repositories(project),
        )
        settings = json.loads((temporary / "config/settings.json").read_text())
        settings["defaultTools"] = [
            "read",
            "write",
            "edit",
            "bash",
            "recovery_list",
            "recovery_restore",
            "codemode",
        ]
        (temporary / "config/settings.json").write_text(json.dumps(settings))
        environment = sandbox_environment(node=node, temporary=temporary)
        environment["PI_SANDBOX_CONTROL"] = "1"
        controller = editing_controller(
            node=node,
            cli=cli,
            project=project,
            state=state,
            assets=assets_root(),
            roots=roots,
        )
        command = sandbox_prefix(
            node=node,
            cli=cli,
            project=project,
            state=state,
            temporary=temporary,
            assets=assets_root(),
            roots=roots,
        )

        def connect(_host):
            return http.client.HTTPConnection(
                "localhost", model.server_port, timeout=10
            )

        with serve(
            Broker(
                temporary / "gateway.sock",
                key="host-only-test-secret",
                connect=connect,
                controller=controller,
            )
        ):
            try:
                result = subprocess.run(
                    [
                        *command,
                        str(node),
                        str(cli),
                        "-p",
                        "--no-session",
                        "--no-mcp",
                        "--no-approve",
                        "--thinking",
                        "off",
                        "Edit the fixture",
                    ],
                    cwd=project,
                    env=environment,
                    capture_output=True,
                    text=True,
                    timeout=45,
                    check=False,
                )
                abort_source = r"""
                    import { existsSync } from 'node:fs';
                    const controller = new AbortController();
                    const deadline = setTimeout(() => controller.abort(), 10000);
                    const watcher = setInterval(() => {
                        if (existsSync('bridge-ticks')) controller.abort();
                    }, 50);
                    try {
                        const response = await fetch('http://pi-gateway.invalid/control', {
                            method: 'POST', headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ tool: 'bash', args: {
                                command: 'setsid sh -c "while :; do echo tick >> bridge-ticks; sleep 0.05; done" & wait',
                                timeout: 30,
                            }}), signal: controller.signal,
                        });
                        for await (const chunk of response.body) {}
                    } catch (error) {
                        console.log(error.name);
                    } finally {
                        clearInterval(watcher);
                        clearTimeout(deadline);
                    }
                """
                aborted = subprocess.run(
                    [
                        *command,
                        str(node),
                        "--input-type=module",
                        "--eval",
                        abort_source,
                    ],
                    cwd=project,
                    env=environment,
                    capture_output=True,
                    text=True,
                    timeout=15,
                    check=False,
                )
                assert aborted.stdout.strip() == "AbortError", aborted.stderr
                import time

                time.sleep(0.5)
                size = (project / "bridge-ticks").stat().st_size
                time.sleep(0.3)
                assert (project / "bridge-ticks").stat().st_size == size
                shared_history = controller.history(0)
                checkpoint = next(
                    entry["checkpoint"]
                    for entry in reversed(shared_history)
                    if entry["repo"] == str(shared[2])
                    and entry["label"] == "bash"
                    and entry["status"] == "completed"
                )
                restored = list(
                    controller.execute(
                        parse_request(
                            {
                                "tool": "recovery_restore",
                                "args": {"checkpoint": checkpoint, "paths": ["file"]},
                            }
                        ),
                        threading.Event(),
                    )
                )[0]["result"]["paths"]
            finally:
                controller.close()
        assert result.returncode == 0, result.stderr
        assert result.stdout.strip() == "editing complete"
        assert (project / "visible.txt").read_text() == "after"
        assert (project / "shell.txt").read_text() == "shell"
        assert not (project / "uncheckpointed").exists()
        assert (shared[0] / "file").read_text() == "shared"
        assert (shared[1] / "file").read_text() == "private knowledge"
        assert Path(restored[0]).read_text() == "edited forge"
        assert (project / ".zprofile").read_bytes() == b""
        assert (project / ".zprofile").stat().st_ino == zprofile_inode
        assert (
            project / ".claude/settings.local.json"
        ).read_bytes() == b'{"allowed":true}'
        for path in (".bashrc", ".gitconfig", ".claude/agents", ".claude/commands"):
            assert not (project / path).exists(), path
        assert [entry["label"] for entry in controller.recovery.list()] == [
            "bash",
            "bash",
            "edit",
            "write",
        ]
        assert len(calls) == 5
        assert not (root / "outside.txt").exists()
        assert "approved repositories" in json.dumps(calls[-1])


def test_native_worker_protects_shared_aliases_and_leaves_source_writable():
    import subprocess

    from launcher import assets_root, editing_controller
    from runtime import find_runtime

    node, cli = find_runtime()
    with tempfile.TemporaryDirectory(prefix="pi-shared-files-") as directory:
        root = Path(directory)
        project = root / "repo"
        project.mkdir()
        subprocess.run(["/usr/bin/git", "init", "-q", str(project)], check=True)
        sentinel = root / "cache"
        sentinel.write_text("cached package")
        sentinel.chmod(0o644)
        dependencies = project / "setup/.venv/lib"
        dependencies.mkdir(parents=True)
        (dependencies / "package.py").hardlink_to(sentinel)
        (dependencies / "second.py").hardlink_to(sentinel)
        (project / "shared.py").hardlink_to(sentinel)
        (project / "alias.py").symlink_to("shared.py")
        state = root / "private/project"
        for name in ("sessions", "cache"):
            (state / name).mkdir(parents=True)
        controller = editing_controller(
            node=node, cli=cli, project=project, state=state, assets=assets_root()
        )
        try:
            list(
                controller.execute(
                    parse_request(
                        {
                            "tool": "write",
                            "args": {"path": "source.py", "content": "first"},
                        }
                    ),
                    threading.Event(),
                )
            )
            (project / "late.py").hardlink_to(sentinel)
            messages = list(
                controller.execute(
                    parse_request(
                        {
                            "tool": "bash",
                            "args": {
                                "command": """
                    set -eu
                    printf fresh > source.py
                    for path in setup/.venv/lib/package.py setup/.venv/lib/second.py shared.py late.py; do
                        if { printf damaged >> "$path"; } 2>/dev/null; then exit 10; fi
                        if chmod 600 "$path" 2>/dev/null; then exit 11; fi
                        if ln "$path" bypass.py 2>/dev/null; then exit 12; fi
                        if mv "$path" moved.py 2>/dev/null; then exit 13; fi
                    done
                    if { printf damaged >> alias.py; } 2>/dev/null; then exit 14; fi
                    if chmod 600 alias.py 2>/dev/null; then exit 15; fi
                    if ln -L alias.py bypass.py 2>/dev/null; then exit 16; fi
                    printf protected
                """
                            },
                        }
                    ),
                    threading.Event(),
                )
            )
            assert messages[-1]["result"]["content"] == [
                {"type": "text", "text": "protected"}
            ]
            assert (project / "source.py").read_text() == "fresh"
            assert sentinel.read_text() == "cached package"
            assert sentinel.stat().st_mode & 0o777 == 0o644
            assert (dependencies / "package.py").stat().st_nlink == 5
            checkpoint = controller.recovery.list()[0]["checkpoint"]
            restored = controller.recovery.restore(checkpoint, ["shared.py"])
            assert (project / restored[0]).read_text() == "cached package"
            assert sentinel.read_text() == "cached package"
        finally:
            controller.close()
