import contextlib
import dataclasses
import fcntl
import json
import os
import re
import selectors
import signal
import subprocess
import threading
import time
from collections.abc import Callable, Iterator, Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import NewType, assert_never

from recovery import Recovery, relative_path

RunId = NewType("RunId", str)

MAX_MESSAGE = 8 * 1024 * 1024
MAX_OUTPUT = 256 * 1024


@dataclass(frozen=True)
class Write:
    path: str
    content: str


@dataclass(frozen=True)
class Replacement:
    oldText: str
    newText: str


@dataclass(frozen=True)
class Edit:
    path: str
    edits: tuple[Replacement, ...]


@dataclass(frozen=True)
class Bash:
    command: str
    timeout: float = 300
    writablePaths: tuple[str, ...] = ()


@dataclass(frozen=True)
class ReadonlyBash:
    command: str
    runId: RunId
    timeout: float = 300


@dataclass(frozen=True)
class CancelReadonly:
    runId: RunId


@dataclass(frozen=True)
class ListRecovery:
    offset: int = 0
    checkpoint: str = ""


@dataclass(frozen=True)
class Restore:
    checkpoint: str
    paths: tuple[str, ...]


Command = Write | Edit | Bash | ReadonlyBash
Request = Command | ListRecovery | Restore | CancelReadonly


def run_id(value: object):
    value = text(value)
    if not re.fullmatch(r"[A-Za-z0-9-]{1,80}", value):
        raise ValueError("Invalid read-only run ID")
    return RunId(value)


def object_value(value: object):
    if not isinstance(value, dict) or not all(isinstance(key, str) for key in value):
        raise ValueError("Expected JSON object")
    return value


def text(value: object):
    if not isinstance(value, str) or "\x00" in value:
        raise ValueError("Expected text without NUL bytes")
    return value


def tool_path(value: object):
    value = text(value)
    if not value or ".." in value.split("/"):
        raise ValueError("Use absolute or relative paths without traversal")
    return str(Path(value))


def parse_request(value: object) -> Request:
    request = object_value(value)
    args = object_value(request.get("args"))
    tool = text(request.get("tool"))
    match tool:
        case "write":
            return Write(tool_path(args.get("path")), text(args.get("content")))
        case "edit":
            edits = args.get("edits")
            if not isinstance(edits, list) or not 1 <= len(edits) <= 1000:
                raise ValueError("Expected 1 to 1000 edits")
            replacements = []
            for edit_value in edits:
                edit = object_value(edit_value)
                replacements.append(
                    Replacement(text(edit.get("oldText")), text(edit.get("newText")))
                )
            return Edit(tool_path(args.get("path")), tuple(replacements))
        case "bash" | "readonly_bash":
            if tool == "readonly_bash" and "writablePaths" in args:
                raise ValueError("Read-only commands cannot request writablePaths")
            paths = args.get("writablePaths", [])
            if not isinstance(paths, list) or len(paths) > 50:
                raise ValueError("Expected at most 50 writable directories")
            timeout = args.get("timeout", 300)
            if (
                isinstance(timeout, bool)
                or not isinstance(timeout, (int, float))
                or not 0 < timeout <= 3600
            ):
                raise ValueError("Timeout must be 0 to 3600 seconds")
            if tool == "readonly_bash":
                return ReadonlyBash(
                    command=text(args.get("command")),
                    runId=run_id(args.get("runId")),
                    timeout=timeout,
                )
            return Bash(
                text(args.get("command")),
                timeout,
                tuple(tool_path(path) for path in paths),
            )
        case "readonly_cancel":
            return CancelReadonly(run_id(args.get("runId")))
        case "recovery_list":
            offset = args.get("offset", 0)
            if isinstance(offset, bool) or not isinstance(offset, int) or offset < 0:
                raise ValueError("Invalid recovery offset")
            return ListRecovery(offset, text(args.get("checkpoint", "")))
        case "recovery_restore":
            paths = args.get("paths")
            if not isinstance(paths, list) or not 1 <= len(paths) <= 50:
                raise ValueError("Recover 1 to 50 paths")
            return Restore(
                text(args.get("checkpoint")),
                tuple(str(relative_path(text(path))) for path in paths),
            )
        case _:
            raise ValueError("Unsupported controller tool")


def worker_request(request: Command):
    match request:
        case Write():
            tool = "write"
        case Edit():
            tool = "edit"
        case Bash() | ReadonlyBash():
            tool = "bash"
        case _ as unreachable:
            assert_never(unreachable)
    return {"tool": tool, "args": dataclasses.asdict(request)}


class Controller:
    def __init__(
        self,
        recovery: Recovery,
        *,
        run: Callable[[Command, threading.Event, int], Iterator[Mapping[str, object]]],
        recoveries: Sequence[Recovery] = (),
        cwd: Path | None = None,
    ):
        self.recovery = recovery
        self.recoveries = tuple(recoveries) or (recovery,)
        if any(store.root != recovery.root for store in self.recoveries):
            raise ValueError("Repositories must share the recovery store")
        self.cwd = cwd or recovery.repo
        self.run = run
        self._active = set()
        self._guard = threading.Condition()
        self._closed = False
        self._readonly: dict[RunId, threading.Event] = {}
        self._cancelled: set[RunId] = set()

    def cancel_readonly(self, run_id: RunId):
        with self._guard:
            # Retain cancelled admissions until shutdown: eviction could let a
            # delayed HTTP request start after its cancellation was acknowledged.
            if len(self._cancelled) < 1024:
                self._cancelled.add(run_id)
            stop = self._readonly.get(run_id)
            if stop is not None:
                stop.set()
            while run_id in self._readonly:
                self._guard.wait(timeout=0.1)

    @contextlib.contextmanager
    def readonly_operation(self, request: ReadonlyBash, stop: threading.Event):
        with self._guard:
            if self._closed or request.runId in self._cancelled or stop.is_set():
                raise RuntimeError("Read-only operation cancelled")
            if len(self._cancelled) >= 1024:
                raise RuntimeError(
                    "Read-only cancellation budget exhausted; restart Pi"
                )
            if request.runId in self._readonly:
                raise ValueError("Duplicate read-only run ID")
            if len(self._readonly) >= 4:
                raise RuntimeError(
                    "At most four read-only commands may run concurrently"
                )
            self._readonly[request.runId] = stop
            self._active.add(stop)
        try:
            # The supervisor expects a retained descriptor; this is not a lock.
            with open(os.devnull, "rb") as descriptor:
                yield descriptor.fileno()
        finally:
            with self._guard:
                self._readonly.pop(request.runId)
                self._active.discard(stop)
                self._guard.notify_all()

    def close(self):
        with self._guard:
            self._closed = True
            for event in self._active:
                event.set()
            while self._active:
                self._guard.wait(timeout=0.1)

    @contextlib.contextmanager
    def operation(self, stop: threading.Event):
        with self._guard:
            if self._closed:
                raise RuntimeError("Sandbox controller stopped")
            self._active.add(stop)
        # Every session can edit shared repos. The worker retains this global lock.
        lock_path = self.recovery.root / "operation.lock"
        try:
            with lock_path.open("a+b") as lock:
                while True:
                    if stop.is_set():
                        raise RuntimeError("Operation cancelled")
                    try:
                        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                        break
                    except BlockingIOError:
                        stop.wait(0.1)
                with self.recovery.locked() as database:
                    # This lock establishes that no previous worker is live.
                    database.execute(
                        'UPDATE checkpoints SET status="interrupted" WHERE status IN ("active","recovering")',
                    )
                yield lock.fileno()
        finally:
            with self._guard:
                self._active.discard(stop)
                self._guard.notify_all()

    def target(self, path: str):
        candidate = Path(path).expanduser()
        if not candidate.is_absolute():
            candidate = self.cwd / candidate
        if not any(candidate.is_relative_to(store.repo) for store in self.recoveries):
            raise ValueError("Target must stay within approved repositories")
        resolved = candidate.resolve()
        for store in self.recoveries:
            if resolved.is_relative_to(store.repo):
                if store.excluded(resolved.relative_to(store.repo)):
                    raise ValueError("Target is protected by the sandbox")
                return store, resolved
        raise ValueError("Symlink target must stay within approved repositories")

    def checkpoint_store(self, checkpoint: str):
        with self.recovery.locked() as database:
            row = database.execute(
                "SELECT repo FROM checkpoints WHERE id=?", (checkpoint,)
            ).fetchone()
        for store in self.recoveries:
            if row and store.repo_id == row[0]:
                return store
        raise ValueError("Unknown checkpoint")

    def history(self, offset: int):
        stores = {store.repo_id: store for store in self.recoveries}
        placeholders = ",".join("?" for _ in stores)
        with self.recovery.locked() as database:
            return [
                {
                    **dict(
                        zip(
                            ("checkpoint", "label", "status", "files", "last_recovery"),
                            row[:5],
                            strict=True,
                        )
                    ),
                    "repo": str(stores[row[5]].repo),
                }
                for row in database.execute(
                    f"""SELECT id,label,status,(SELECT count(*) FROM entries WHERE checkpoint=c.id), (SELECT status FROM exports WHERE checkpoint=c.id ORDER BY created DESC LIMIT 1),repo FROM checkpoints c WHERE repo IN ({placeholders}) AND status != 'staging' ORDER BY created DESC LIMIT 20 OFFSET ?""",
                    (*stores, offset),
                )
            ]

    def execute(self, request: Request, stop: threading.Event):
        if isinstance(request, CancelReadonly):
            self.cancel_readonly(request.runId)
            yield {"type": "result", "result": {"cancelled": True}}
            return
        if isinstance(request, ReadonlyBash):
            result = None
            with self.readonly_operation(request, stop) as descriptor:
                for message in self.run(request, stop, descriptor):
                    if message.get("type") == "result":
                        result = message
                    else:
                        yield message
            if result is None:
                raise RuntimeError("Read-only command stopped before completing")
            yield result
            return
        with self.operation(stop) as lock_fd:
            match request:
                case ListRecovery():
                    if request.checkpoint:
                        result = self.checkpoint_store(request.checkpoint).paths(
                            request.checkpoint, offset=request.offset
                        )
                    else:
                        result = self.history(request.offset)
                    yield {
                        "type": "result",
                        "result": {
                            "entries": result,
                            "next_offset": request.offset + len(result),
                        },
                    }
                case Restore():
                    store = self.checkpoint_store(request.checkpoint)
                    paths = store.restore(request.checkpoint, request.paths)
                    if store.repo != self.cwd:
                        paths = [str(store.repo / path) for path in paths]
                    yield {"type": "result", "result": {"paths": paths}}
                case Write() | Edit() | Bash():
                    selections = {}
                    if isinstance(request, (Write, Edit)):
                        store, target = self.target(request.path)
                        request = dataclasses.replace(request, path=str(target))
                        selections[store] = [target.relative_to(store.repo)]
                    else:
                        values = request.writablePaths
                        if not values and any(
                            self.cwd.is_relative_to(store.repo)
                            for store in self.recoveries
                        ):
                            values = (str(self.cwd),)
                        directories = []
                        for value in values:
                            store, directory = self.target(value)
                            if not directory.is_dir():
                                raise ValueError(
                                    "Bash writablePaths must be existing directories"
                                )
                            selections.setdefault(store, []).append(
                                directory.relative_to(store.repo)
                            )
                            directories.append(str(directory))
                        request = dataclasses.replace(
                            request, writablePaths=tuple(directories)
                        )
                    checkpoints = []
                    completed = False
                    try:
                        for store, paths in selections.items():
                            checkpoints.append(
                                (
                                    store,
                                    store.checkpoint(
                                        type(request).__name__.lower(), paths=paths
                                    ),
                                )
                            )
                        if stop.is_set():
                            raise RuntimeError("Operation cancelled")
                        yield from self.run(request, stop, lock_fd)
                        completed = True
                    finally:
                        for store, checkpoint in checkpoints:
                            store.complete(checkpoint, interrupted=not completed)
                case _ as unreachable:
                    assert_never(unreachable)


class Worker:
    def __init__(
        self,
        *,
        command: Callable[[int], list[str]],
        environment: Mapping[str, str],
        repo: Path,
    ):
        self.command = command
        self.environment = environment
        self.repo = repo

    def __call__(self, request: Command, stop: threading.Event, lock_fd: int):
        reader, writer = os.pipe()
        process = None
        try:
            process = subprocess.Popen(
                self.command(reader),
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                env=self.environment,
                cwd=self.repo,
                pass_fds=(reader, lock_fd),
                start_new_session=True,
            )
            os.close(reader)
            reader = -1
            input_stream, output_stream = process.stdin, process.stdout
            if input_stream is None or output_stream is None:
                raise RuntimeError("Worker pipes were not created")
            input_stream.write(json.dumps(worker_request(request)).encode() + b"\n")
            input_stream.close()
            os.set_blocking(output_stream.fileno(), False)
            selector = selectors.DefaultSelector()
            selector.register(output_stream, selectors.EVENT_READ)
            pending = bytearray()
            result_seen = False
            deadline = (
                time.monotonic()
                + (
                    request.timeout
                    if isinstance(request, (Bash, ReadonlyBash))
                    else 300
                )
                + 30
            )
            try:
                while True:
                    if stop.is_set() or time.monotonic() >= deadline:
                        raise RuntimeError("Sandbox operation cancelled or timed out")
                    if selector.select(0.1):
                        chunk = os.read(output_stream.fileno(), 65536)
                        if not chunk:
                            break
                        pending.extend(chunk)
                        while b"\n" in pending:
                            line, _, remainder = pending.partition(b"\n")
                            if len(line) > MAX_OUTPUT:
                                raise RuntimeError(
                                    "Worker output exceeds transport limit"
                                )
                            pending = bytearray(remainder)
                            message = object_value(json.loads(line))
                            if message.get("type") == "error":
                                raise RuntimeError(text(message.get("error"))[:2000])
                            if message.get("type") not in {
                                "update",
                                "result",
                            } or not isinstance(message.get("result"), dict):
                                raise RuntimeError("Invalid sandbox worker message")
                            result_seen |= message.get("type") == "result"
                            yield message
                        if len(pending) > MAX_OUTPUT:
                            raise RuntimeError("Worker output exceeds transport limit")
                process.wait(timeout=5)
                if process.returncode != 0 or not result_seen:
                    raise RuntimeError("Sandbox worker stopped before completing")
            finally:
                selector.close()
        finally:
            os.close(writer)
            if reader >= 0:
                os.close(reader)
            if process is not None:
                # Let the supervisor stop bwrap and clean its tracked mount placeholders.
                try:
                    process.send_signal(signal.SIGTERM)
                    process.wait(timeout=1)
                except (ProcessLookupError, subprocess.TimeoutExpired):
                    pass
                # Kill SRT's intermediate shell too; bwrap then kills its PID namespace.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait()
                if process.stdout is not None:
                    process.stdout.close()
