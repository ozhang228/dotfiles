import fcntl
import hashlib
import http.client
import json
import os
import stat
import tempfile
import threading
from pathlib import Path

MAX_CATALOG_BYTES = 2 * 1024 * 1024
MAX_CATALOG_FILES = 32
CATALOG_TIMEOUT = 4


def valid_catalog(body: bytes, path: str):
    try:
        value = json.loads(body)
    except (ValueError, UnicodeError):
        return False
    return isinstance(value, dict) and (
        path != "/v1/models" or isinstance(value.get("data"), list)
    )


class CatalogCache:
    def __init__(self, root: Path, *, key: str, connect):
        root.mkdir(mode=0o700, parents=True, exist_ok=True)
        if root.resolve() != root or root.stat().st_uid != os.getuid():
            raise RuntimeError("Model catalogue cache must be private and owned")
        root.chmod(0o700)
        self.root = root
        self.key = key
        self.connect = connect
        self._guard = threading.Lock()
        self._refreshed: set[Path] = set()

    def path(self, *, host: str, path: str):
        scope = "\0".join((self.key, host, path)).encode()
        return self.root / (hashlib.sha256(scope).hexdigest() + ".json")

    def read(self, file: Path, *, path: str):
        try:
            descriptor = os.open(file, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
            with os.fdopen(descriptor, "rb") as stream:
                info = os.fstat(stream.fileno())
                if (
                    not stat.S_ISREG(info.st_mode)
                    or info.st_uid != os.getuid()
                    or info.st_mode & 0o077
                    or info.st_size > MAX_CATALOG_BYTES
                ):
                    return None
                body = stream.read(MAX_CATALOG_BYTES + 1)
            if len(body) <= MAX_CATALOG_BYTES and valid_catalog(body, path):
                return body
        except OSError:
            pass
        return None

    def store(self, file: Path, body: bytes):
        with self._guard, (self.root / "lock").open("a+b") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            files = []
            for candidate in self.root.glob("*.json"):
                info = candidate.lstat()
                if (
                    candidate != file
                    and stat.S_ISREG(info.st_mode)
                    and info.st_uid == os.getuid()
                ):
                    files.append((info.st_mtime_ns, candidate))
            for _, oldest in sorted(files)[
                : max(0, len(files) - MAX_CATALOG_FILES + 1)
            ]:
                oldest.unlink(missing_ok=True)
            with tempfile.NamedTemporaryFile(dir=self.root, delete=False) as stream:
                temporary = Path(stream.name)
                try:
                    stream.write(body)
                    stream.close()
                    os.replace(temporary, file)
                finally:
                    temporary.unlink(missing_ok=True)

    def fetch(self, *, host: str, path: str):
        upstream = self.connect(host)
        upstream.timeout = CATALOG_TIMEOUT
        try:
            headers = {"Accept": "application/json"}
            if host == "ai.drwcloud.com":
                headers.update(
                    {
                        "x-portkey-api-key": self.key,
                        "x-portkey-metadata": '{"service":"pi"}',
                    }
                )
            upstream.request("GET", path, headers=headers)
            response = upstream.getresponse()
            if response.status != 200:
                return (
                    502 if 300 <= response.status < 400 else response.status,
                    b"Gateway upstream unavailable\n",
                )
            body = response.read(MAX_CATALOG_BYTES + 1)
            if len(body) > MAX_CATALOG_BYTES or not valid_catalog(body, path):
                return 502, b"Gateway catalogue unavailable\n"
            self.store(self.path(host=host, path=path), body)
            return 200, body
        except (OSError, http.client.HTTPException):
            return 502, b"Gateway catalogue unavailable\n"
        finally:
            upstream.close()

    def get(self, *, host: str, path: str):
        file = self.path(host=host, path=path)
        body = self.read(file, path=path)
        if body is None:
            return self.fetch(host=host, path=path)
        with self._guard:
            if file not in self._refreshed and len(self._refreshed) < MAX_CATALOG_FILES:
                self._refreshed.add(file)
                threading.Thread(
                    target=self.fetch, kwargs={"host": host, "path": path}, daemon=True
                ).start()
        return 200, body
