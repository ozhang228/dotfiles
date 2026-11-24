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


class Broker(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
    daemon_threads = True

    def __init__(self, path: Path, *, controller: Controller | None = None):
        self.controller = controller
        super().__init__(str(path), GatewayHandler)
        path.chmod(0o600)

    def handle_error(self, request, client_address):
        # Failures must never log tool arguments or file contents.
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

    def reply(self, status: int, body: bytes, *, content_type="text/plain"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
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
        self.reply(403, b"Gateway request denied\n")
