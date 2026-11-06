import http.client
import json
import re
import select
import socket
import socketserver
import threading
from http.server import BaseHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlsplit

from controller import Controller, parse_request

MAX_BODY_BYTES = 8 * 1024 * 1024
IDLE_TIMEOUT = 60


def destination(*, method: str, path: str):
    if path.startswith("http://"):
        request = urlsplit(path)
        if request.netloc != "pi-gateway.invalid" or request.query or request.fragment:
            return None
        path = request.path
    if (method, path) in {
        ("GET", "/v1/models"),
        ("POST", "/v1/responses"),
        ("POST", "/v1/chat/completions"),
    }:
        return "ai.drwcloud.com", path
    if method == "GET" and re.fullmatch(
        r"/metadata/(pricing|general)/[A-Za-z0-9_-]+\.json", path
    ):
        return "configs.portkey.ai", path.removeprefix("/metadata")
    return None


class Broker(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
    daemon_threads = True

    def __init__(
        self,
        path: Path,
        *,
        key: str,
        connect=None,
        controller: Controller | None = None,
    ):
        self.controller = controller
        self.key = key
        self.connect = connect or (
            lambda host: http.client.HTTPSConnection(host, timeout=IDLE_TIMEOUT)
        )
        super().__init__(str(path), GatewayHandler)
        path.chmod(0o600)

    def handle_error(self, request, client_address):
        # HTTP failures must never log credentials, prompts, or upstream payloads.
        pass


class GatewayHandler(BaseHTTPRequestHandler):
    @property
    def gateway(self):
        if not isinstance(self.server, Broker):
            raise TypeError("Unexpected gateway server")
        return self.server

    def setup(self):
        super().setup()
        self.connection.settimeout(IDLE_TIMEOUT)

    def log_message(self, format, *args):
        pass

    def send_error(self, code, message=None, explain=None):
        self.reply(code, b"Gateway request denied\n")

    def reply(self, status: int, body: bytes):
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        self.forward()

    def do_POST(self):
        self.forward()

    def do_CONNECT(self):
        if self.path != "pi-gateway.invalid:80":
            self.reply(403, b"Gateway request denied\n")
            return
        # Pi tunnels even plaintext HTTP through its proxy. Keep the tunnel
        # inside this handler so every subsequent request retains the path gate.
        self.send_response(200)
        self.end_headers()
        self.close_connection = False

    def control(self):

        controller = self.gateway.controller
        if controller is None:
            self.reply(403, b"Controller unavailable\n")
            return
        lengths = self.headers.get_all("Content-Length", [])
        if (
            self.headers.get("Transfer-Encoding")
            or self.headers.get("Content-Encoding")
            or len(lengths) != 1
            or not re.fullmatch(r"[0-9]+", lengths[0])
        ):
            self.reply(403, b"Controller request denied\n")
            return
        length = int(lengths[0])
        if length > MAX_BODY_BYTES:
            self.reply(413, b"Controller request too large\n")
            return
        stopped = threading.Event()

        def cancel_on_disconnect():
            while not stopped.wait(0.1):
                try:
                    readable, _, _ = select.select([self.connection], [], [], 0)
                    if readable and not self.connection.recv(1, socket.MSG_PEEK):
                        stopped.set()
                        return
                except OSError:
                    stopped.set()
                    return

        watcher = None
        try:
            body = self.rfile.read(length)
            if len(body) != length:
                return
            request = parse_request(json.loads(body))
            self.send_response(200)
            self.send_header("Content-Type", "application/x-ndjson")
            self.send_header("Connection", "close")
            self.end_headers()
            self.close_connection = True
            watcher = threading.Thread(target=cancel_on_disconnect, daemon=True)
            watcher.start()
            for message in controller.execute(request, stopped):
                self.wfile.write(json.dumps(message).encode() + b"\n")
                self.wfile.flush()
        except (OSError, ValueError, RuntimeError) as error:
            try:
                if watcher is None:
                    self.reply(
                        400,
                        f"Invalid controller request: {str(error)[:2000]}\n".encode(),
                    )
                else:
                    self.wfile.write(
                        json.dumps(
                            {"type": "error", "error": str(error)[:2000]}
                        ).encode()
                        + b"\n"
                    )
                    self.wfile.flush()
            except OSError:
                pass
        finally:
            stopped.set()
            if watcher is not None:
                watcher.join(timeout=1)

    def forward(self):
        parsed = urlsplit(self.path)
        if (
            self.command == "POST"
            and parsed.path == "/control"
            and not parsed.query
            and not parsed.fragment
            and parsed.netloc in {"", "pi-gateway.invalid"}
            and self.gateway.controller is not None
        ):
            self.control()
            return
        target = destination(method=self.command, path=self.path)
        if target is None:
            self.reply(403, b"Gateway request denied\n")
            return
        lengths = self.headers.get_all("Content-Length", [])
        if (
            self.headers.get("Transfer-Encoding")
            or self.headers.get("Content-Encoding")
            or self.headers.get("Upgrade")
            or len(lengths) > 1
            or (lengths and not re.fullmatch(r"[0-9]+", lengths[0]))
        ):
            self.reply(403, b"Gateway request denied\n")
            return
        length = int(lengths[0]) if lengths else 0
        if length > MAX_BODY_BYTES or (self.command == "GET" and length):
            self.reply(413, b"Gateway request denied\n")
            return
        host, path = target
        headers = {
            "Content-Type": "application/json",
            "Accept": "text/event-stream, application/json",
        }
        if host == "ai.drwcloud.com":
            headers.update(
                {
                    "x-portkey-api-key": self.gateway.key,
                    "x-portkey-metadata": '{"service":"pi"}',
                }
            )
            strict = self.headers.get("x-portkey-strict-open-ai-compliance")
            if strict in {"true", "false"}:
                headers["x-portkey-strict-open-ai-compliance"] = strict
        upstream = self.gateway.connect(host)
        response_started = False
        stopped = threading.Event()
        watcher = None
        try:
            body = self.rfile.read(length)
            if len(body) != length:
                return
            upstream.request(
                self.command, path, body=body if length else None, headers=headers
            )
            upstream_socket = upstream.sock

            def cancel_on_disconnect():
                while not stopped.wait(0.1):
                    try:
                        readable, _, _ = select.select([self.connection], [], [], 0)
                        if readable and not self.connection.recv(1, socket.MSG_PEEK):
                            upstream_socket.shutdown(socket.SHUT_RDWR)
                            return
                    except OSError:
                        return

            watcher = threading.Thread(target=cancel_on_disconnect, daemon=True)
            watcher.start()
            response = upstream.getresponse()
            if 300 <= response.status < 400:
                self.reply(502, b"Gateway upstream unavailable\n")
                return
            self.send_response(response.status)
            for header in (
                "Content-Type",
                "Content-Length",
                "Content-Encoding",
                "Retry-After",
                "x-request-id",
            ):
                if header == "Content-Length" and response.getheader(
                    "Transfer-Encoding"
                ):
                    continue
                value = response.getheader(header)
                if value is not None:
                    self.send_header(header, value)
            self.end_headers()
            response_started = True
            while chunk := response.read1(64 * 1024):
                self.wfile.write(chunk)
                self.wfile.flush()
        except (OSError, http.client.HTTPException):
            if not response_started:
                self.reply(502, b"Gateway upstream unavailable\n")
        finally:
            stopped.set()
            upstream.close()
            if watcher is not None:
                watcher.join(timeout=1)
