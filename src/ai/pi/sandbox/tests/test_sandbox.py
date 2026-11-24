import contextlib
import http.client
import importlib.util
import socket
import subprocess
import sys
import tempfile
import threading
from pathlib import Path
from unittest.mock import patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


def load_module(name):
    spec = importlib.util.spec_from_file_location(
        name,
        (Path(__file__).parent if name == "smoke" else Path(__file__).parents[1])
        / f"{name}.py",
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_proc_check_rejects_host_proc_mount_and_missing_namespace_info():
    smoke = load_module("smoke")
    with pytest.raises(RuntimeError, match="Host PID namespace visible"):
        smoke.require_private_proc(status="NSpid:\t4140413\t2\n", pid=2)
    with pytest.raises(RuntimeError, match="Missing /proc PID namespace"):
        smoke.require_private_proc(status="Name:\tpython3\n", pid=2)


class UnixHTTPConnection(http.client.HTTPConnection):
    def connect(self):
        self.sock = socket.socket(socket.AF_UNIX)
        self.sock.settimeout(self.timeout)
        self.sock.connect(self.host)


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


def test_broker_denies_everything_but_the_controller():
    broker = load_module("broker")
    with (
        tempfile.TemporaryDirectory() as directory,
        serve(broker.Broker(Path(directory) / "gateway.sock")) as gateway,
    ):
        for method, path in (
            ("GET", "http://pi-gateway.invalid/v1/models"),
            ("POST", "http://pi-gateway.invalid/v1/responses"),
            ("POST", "http://pi-gateway.invalid/control"),
        ):
            client = UnixHTTPConnection(gateway.server_address, timeout=2)
            client.request(method, path, body=b"{}" if method == "POST" else None)
            response = client.getresponse()
            assert response.status == 403
            response.read()
            client.close()
        with socket.socket(socket.AF_UNIX) as tunnel:
            tunnel.settimeout(2)
            tunnel.connect(gateway.server_address)
            tunnel.sendall(
                b"CONNECT unapproved.invalid:443 HTTP/1.1\r\nHost: unapproved.invalid:443\r\n\r\n"
            )
            assert tunnel.recv(64).startswith(b"HTTP/1.0 403")


def test_launcher_refuses_unavailable_boundary_and_scans_protections():
    launcher = load_module("launcher")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        calls = []

        def unavailable(command, **options):
            calls.append(command)
            return subprocess.CompletedProcess(command, 1, "", "Namespace setup denied")

        with patch.object(launcher.subprocess, "run", side_effect=unavailable):
            try:
                launcher.check_boundary(["srt", "/usr/bin/true"], environment={})
            except RuntimeError as error:
                assert (
                    str(error)
                    == "Sandbox isolation unavailable; Pi was not started\nNamespace setup denied"
                )
            else:
                raise AssertionError("Unrestricted fallback accepted")
        assert calls == [["srt", "/usr/bin/true"]]
        project = root / "project"
        (project / ".pi/nested").mkdir(parents=True)
        (project / ".pi/nested/.env").touch()
        (project / "nested").mkdir()
        (project / "nested/.env").touch()
        (project / ".git").mkdir()
        (project / ".git/.env").touch()
        (project / "nested/.git").write_text("gitdir: elsewhere")
        protections = launcher.repository_protections(project)
        assert set(protections.credentials) == {
            project / ".pi",
            project / "nested/.env",
            project / ".git/.env",
        }
        assert set(protections.git_metadata) == {
            project / ".git",
            project / "nested/.git",
        }
        (project / ".env.link").symlink_to(root / "outside")
        try:
            launcher.repository_protections(project)
        except RuntimeError as error:
            assert str(error) == "Sandbox refuses project .pi or dotenv symlinks"
        else:
            raise AssertionError("Credential symlink was accepted")
        (project / ".env.link").unlink()
        (project / "nested/.git").unlink()
        (project / "nested/.git").symlink_to(root / "outside")
        with pytest.raises(RuntimeError, match="Git metadata symlinks"):
            launcher.repository_protections(project)
        assert (
            launcher.repository_protections(project, include_git=False).git_metadata
            == ()
        )


@pytest.mark.parametrize("failure", ["dependency", "protection scan"])
def test_failed_parallel_preflight_never_starts_the_broker(failure):
    launcher = load_module("launcher")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        project = root / "repo"
        project.mkdir()
        with (
            patch.object(launcher.Path, "cwd", return_value=project),
            patch.object(launcher, "approved_repositories", return_value=(project,)),
            patch.object(
                launcher, "find_runtime", return_value=(root / "node", root / "cli")
            ),
            patch.object(launcher, "sandbox_runtime", return_value=(root, root)),
            patch.object(launcher, "assets_root", return_value=root / "assets"),
            patch.object(
                launcher, "private_state", return_value=root / "private/session"
            ),
            patch.object(launcher, "snapshot_config"),
            patch.object(launcher, "sandbox_environment", return_value={}),
            patch.object(
                launcher,
                "check_boundary",
                side_effect=RuntimeError("dependency failed")
                if failure == "dependency"
                else None,
            ),
            patch.object(
                launcher,
                "repository_protections",
                return_value=launcher.RepositoryProtections((), ()),
                side_effect=RuntimeError("protection scan failed")
                if failure == "protection scan"
                else None,
            ),
            patch.object(launcher, "Broker") as broker,
        ):
            with pytest.raises(RuntimeError, match=f"{failure} failed"):
                launcher.main()
            broker.assert_not_called()


def test_broker_validation_errors_explain_invalid_paths_and_json():
    broker = load_module("broker")
    from controller import Controller
    from recovery import Recovery

    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()

        def run(request, stop, lock_fd):
            raise AssertionError("Invalid requests must not start a worker")
            yield

        controller = Controller(Recovery(root / "private", repo=repo), run=run)
        with serve(
            broker.Broker(root / "gateway.sock", controller=controller)
        ):
            for body, explanation in (
                (
                    b'{"tool":"write","args":{"path":"../outside","content":"bad"}}',
                    "without traversal",
                ),
                (b"{", "Expecting property name"),
            ):
                connection = UnixHTTPConnection(str(root / "gateway.sock"), timeout=10)
                connection.request(
                    "POST", "http://pi-gateway.invalid/control", body=body
                )
                response = connection.getresponse()
                assert response.status == 400
                assert explanation in response.read().decode()
                connection.close()
        controller.close()
        assert not (root / "outside").exists()
