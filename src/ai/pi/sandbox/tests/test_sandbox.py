import contextlib
import http.client
import importlib.util
import json
import socket
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
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


def test_broker_preserves_stream_and_blocks_routing_and_redirects():
    broker = load_module("broker")
    requests = []

    class Upstream(BaseHTTPRequestHandler):
        def do_POST(self):
            requests.append(
                (
                    self.path,
                    dict(self.headers),
                    self.rfile.read(int(self.headers["Content-Length"])),
                )
            )
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.end_headers()
            self.wfile.write(b'data: {"usage":{"output_tokens":7}}\n\ndata: [DONE]\n\n')

        def do_GET(self):
            requests.append((self.path, dict(self.headers), b""))
            if self.path == "/v1/models":
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'{"data":[]}')
                return
            self.send_response(302)
            self.send_header("Location", "https://unapproved.invalid/secret")
            self.end_headers()

        def log_message(self, format, *args):
            pass

    with (
        tempfile.TemporaryDirectory() as directory,
        serve(ThreadingHTTPServer(("0.0.0.0", 0), Upstream)) as upstream,
    ):

        def connect(_host):
            return http.client.HTTPConnection(
                "localhost", upstream.server_port, timeout=2
            )

        with serve(
            broker.Broker(
                Path(directory) / "gateway.sock",
                key="host-only-secret",
                connect=connect,
            )
        ) as gateway:
            client = UnixHTTPConnection(gateway.server_address, timeout=2)
            client.request(
                "POST",
                "http://pi-gateway.invalid/v1/responses",
                body=b'{"model":"@azure/test"}',
                headers={
                    "Authorization": "Bearer attacker",
                    "x-portkey-api-key": "dummy",
                    "x-portkey-config": "unapproved",
                    "x-portkey-custom-host": "https://unapproved.invalid",
                    "x-portkey-strict-open-ai-compliance": "false",
                    "Content-Type": "application/json",
                },
            )
            response = client.getresponse()
            assert response.status == 200
            assert (
                response.read()
                == b'data: {"usage":{"output_tokens":7}}\n\ndata: [DONE]\n\n'
            )
            assert requests == [
                (
                    "/v1/responses",
                    {
                        "Host": f"localhost:{upstream.server_port}",
                        "Accept-Encoding": "identity",
                        "Content-Length": "23",
                        "Content-Type": "application/json",
                        "Accept": "text/event-stream, application/json",
                        "x-portkey-api-key": "host-only-secret",
                        "x-portkey-metadata": '{"service":"pi"}',
                        "x-portkey-strict-open-ai-compliance": "false",
                    },
                    b'{"model":"@azure/test"}',
                )
            ]
            for method, path in (
                ("CONNECT", "ai.drwcloud.com:443"),
                ("GET", "https://unapproved.invalid/v1/models"),
                ("GET", "http://unapproved.invalid/v1/models"),
                ("POST", "/v1/files"),
                ("GET", "/v1/models?route=attacker"),
            ):
                client = UnixHTTPConnection(gateway.server_address, timeout=2)
                client.request(method, path)
                response = client.getresponse()
                assert response.status == 403
                assert response.read() == b"Gateway request denied\n"
            with socket.socket(socket.AF_UNIX) as tunnel:
                tunnel.settimeout(2)
                tunnel.connect(gateway.server_address)
                tunnel.sendall(
                    b"CONNECT pi-gateway.invalid:80 HTTP/1.1\r\nHost: pi-gateway.invalid:80\r\n\r\n"
                    b"GET /v1/files HTTP/1.0\r\n\r\n"
                )
                result = b""
                while part := tunnel.recv(4096):
                    result += part
                assert b"200 OK" in result
                assert b"403 Forbidden" in result
            assert len(requests) == 1
            client = UnixHTTPConnection(gateway.server_address, timeout=2)
            client.request("GET", "/metadata/pricing/openai.json")
            response = client.getresponse()
            assert response.status == 502
            assert response.read() == b"Gateway upstream unavailable\n"
            assert len(requests) == 2
            assert requests[1][0] == "/pricing/openai.json"
            assert "x-portkey-api-key" not in requests[1][1]
            assert "x-portkey-strict-open-ai-compliance" not in requests[1][1]
            client = UnixHTTPConnection(gateway.server_address, timeout=2)
            client.request("GET", "/v1/models")
            response = client.getresponse()
            assert response.read() == b'{"data":[]}'
            assert "x-portkey-strict-open-ai-compliance" not in requests[2][1]


def test_launcher_refuses_unavailable_boundary_and_changed_provider():
    launcher = load_module("launcher")
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        provider = root / "provider.ts"
        provider.write_text('const gateway = "https://changed.invalid/v1";')
        try:
            launcher.adapt_provider(provider)
        except RuntimeError as error:
            assert (
                str(error)
                == "Managed Portkey provider changed; sandbox adaptation refused"
            )
        else:
            raise AssertionError("Changed provider was accepted")
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
        assert list(launcher.credential_paths(project)) == [
            project / ".pi",
            project / "nested/.env",
        ]
        (project / ".env.link").symlink_to(root / "outside")
        try:
            list(launcher.credential_paths(project))
        except RuntimeError as error:
            assert str(error) == "Sandbox refuses project .pi or dotenv symlinks"
        else:
            raise AssertionError("Credential symlink was accepted")


def test_real_pi_streams_through_authenticated_srt_proxy_without_host_auth():
    launcher = load_module("launcher")
    broker = load_module("broker")
    node, cli = launcher.find_runtime()
    _, package = launcher.sandbox_runtime()
    catalog_keys = []
    inference_keys = []

    class Catalog(BaseHTTPRequestHandler):
        def do_POST(self):
            assert self.path == "/v1/responses"
            self.rfile.read(int(self.headers["Content-Length"]))
            inference_keys.append(self.headers.get("x-portkey-api-key"))
            item = {
                "id": "msg_test",
                "type": "message",
                "role": "assistant",
                "status": "completed",
                "content": [
                    {"type": "output_text", "text": "sandbox reply", "annotations": []}
                ],
            }
            response = {
                "id": "resp_test",
                "object": "response",
                "created_at": 1,
                "model": "gpt-5.6-sol",
                "status": "completed",
                "output": [item],
                "usage": {"input_tokens": 1, "output_tokens": 1, "total_tokens": 2},
            }
            events = [
                {
                    "type": "response.created",
                    "response": {**response, "status": "in_progress", "output": []},
                },
                {
                    "type": "response.output_item.added",
                    "output_index": 0,
                    "item": {**item, "status": "in_progress", "content": []},
                },
                {
                    "type": "response.content_part.added",
                    "output_index": 0,
                    "content_index": 0,
                    "part": {"type": "output_text", "text": "", "annotations": []},
                },
                {
                    "type": "response.output_text.delta",
                    "output_index": 0,
                    "content_index": 0,
                    "delta": "sandbox reply",
                },
                {"type": "response.output_item.done", "output_index": 0, "item": item},
                {"type": "response.completed", "response": response},
            ]
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.end_headers()
            for event in events:
                self.wfile.write(f"data: {json.dumps(event)}\n\n".encode())
                self.wfile.flush()

        def do_GET(self):
            if self.path == "/v1/models":
                catalog_keys.append(self.headers.get("x-portkey-api-key"))
            payload = (
                {"data": [{"id": "@azure/gpt-5.6-sol"}]}
                if self.path == "/v1/models"
                else {}
            )
            data = json.dumps(payload).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def log_message(self, format, *args):
            pass

    with (
        tempfile.TemporaryDirectory() as directory,
        serve(ThreadingHTTPServer(("0.0.0.0", 0), Catalog)) as upstream,
    ):

        def connect(_host):
            return http.client.HTTPConnection(
                "localhost", upstream.server_port, timeout=2
            )

        config = Path(directory) / "agent"
        gateway_path = Path(directory) / "gateway.sock"
        proxy_source = (
            "const {createHttpProxyServer}=await import(process.argv[1]);"
            "const proxy=createHttpProxyServer({filter:async(_port,host)=>host==='pi-gateway.invalid',"
            "getMitmSocketPath:()=>process.argv[2],proxyAuthToken:'sandbox-only-token'});"
            "proxy.listen(0,'0.0.0.0',()=>console.log(proxy.address().port));"
        )
        with serve(
            broker.Broker(gateway_path, key="host-only-secret", connect=connect)
        ):
            proxy = subprocess.Popen(
                [
                    str(node),
                    "--input-type=module",
                    "--eval",
                    proxy_source,
                    (package / "dist/sandbox/http-proxy.js").as_uri(),
                    str(gateway_path),
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env={"PATH": "/usr/bin:/bin"},
            )
            try:
                assert proxy.stdout is not None
                port = int(proxy.stdout.readline())
                launcher.snapshot_config(
                    config,
                    assets=launcher.assets_root(),
                    cli=cli,
                    roots=launcher.approved_repositories(Path(directory)),
                )
                environment = {
                    "HOME": directory,
                    "PATH": "/usr/bin",
                    "PORTKEY_API_KEY": "local-broker",
                    "PI_CODING_AGENT_DIR": str(config),
                    "NODE_USE_ENV_PROXY": "1",
                    "HTTP_PROXY": f"http://pi:sandbox-only-token@localhost:{port}",
                    "HTTPS_PROXY": f"http://pi:sandbox-only-token@localhost:{port}",
                }
                result = subprocess.run(
                    [str(node), str(cli), "--list-models", "--no-mcp", "--no-approve"],
                    cwd=directory,
                    env=environment,
                    capture_output=True,
                    text=True,
                    timeout=30,
                    check=False,
                )
                completion = subprocess.run(
                    [
                        str(node),
                        str(cli),
                        "-p",
                        "--no-session",
                        "--no-mcp",
                        "--no-approve",
                        "--thinking",
                        "off",
                        "Say hello",
                    ],
                    cwd=directory,
                    env=environment,
                    capture_output=True,
                    text=True,
                    timeout=30,
                    check=False,
                )
            finally:
                proxy.terminate()
                _, proxy_errors = proxy.communicate(timeout=5)
        assert result.returncode == 0, result.stderr
        assert catalog_keys == ["host-only-secret", "host-only-secret"], (
            result.stderr + proxy_errors
        )
        assert "gpt-5.6-sol" in result.stdout
        assert "Failed to load extension" not in result.stderr
        assert completion.returncode == 0, completion.stderr
        assert completion.stdout.strip() == "sandbox reply"
        assert inference_keys == ["host-only-secret"]
        assert json.loads((config / "auth.json").read_text()) == {}


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
            broker.Broker(root / "gateway.sock", key="unused", controller=controller)
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
