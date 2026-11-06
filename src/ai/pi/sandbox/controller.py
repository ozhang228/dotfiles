import contextlib
import dataclasses
import fcntl
import json
import os
import selectors
import signal
import subprocess
import threading
import time
from collections.abc import Callable, Iterator, Mapping
from dataclasses import dataclass
from pathlib import Path
from typing import assert_never

from recovery import Recovery, relative_path

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


@dataclass(frozen=True)
class ListRecovery:
    offset: int = 0
    checkpoint: str = ""


@dataclass(frozen=True)
class Restore:
    checkpoint: str
    paths: tuple[str, ...]


Request = Write | Edit | Bash | ListRecovery | Restore


def object_value(value: object):
    if not isinstance(value, dict) or not all(isinstance(key, str) for key in value):
        raise ValueError("Expected JSON object")
    return value


def text(value: object):
    if not isinstance(value, str) or "\x00" in value:
        raise ValueError("Expected text without NUL bytes")
    return value


def parse_request(value: object) -> Request:
    request = object_value(value)
    args = object_value(request.get("args"))
    tool = text(request.get("tool"))
    match tool:
        case "write":
            return Write(
                str(relative_path(text(args.get("path")))), text(args.get("content"))
            )
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
            return Edit(str(relative_path(text(args.get("path")))), tuple(replacements))
        case "bash":
            timeout = args.get("timeout", 300)
            if (
                isinstance(timeout, bool)
                or not isinstance(timeout, (int, float))
                or not 0 < timeout <= 3600
            ):
                raise ValueError("Timeout must be 0 to 3600 seconds")
            return Bash(text(args.get("command")), timeout)
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


def worker_request(request: Write | Edit | Bash):
    match request:
        case Write():
            tool = "write"
        case Edit():
            tool = "edit"
        case Bash():
            tool = "bash"
        case _ as unreachable:
            assert_never(unreachable)
    return {"tool": tool, "args": dataclasses.asdict(request)}


class Controller:
    def __init__(
        self,
        recovery: Recovery,
        *,
        run: Callable[
            [Write | Edit | Bash, threading.Event, int], Iterator[Mapping[str, object]]
        ],
    ):
        self.recovery = recovery
        self.run = run
        self._active = set()
        self._guard = threading.Condition()
        self._closed = False

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
        lock_path = self.recovery.root / f"{self.recovery.repo_id}.operation.lock"
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
                    # This repo lock establishes that no previous worker is live.
                    database.execute(
                        'UPDATE checkpoints SET status="interrupted" WHERE repo=? AND status IN ("active","recovering")',
                        (self.recovery.repo_id,),
                    )
                yield lock.fileno()
        finally:
            with self._guard:
                self._active.discard(stop)
                self._guard.notify_all()

    def execute(self, request: Request, stop: threading.Event):
        with self.operation(stop) as lock_fd:
            match request:
                case ListRecovery():
                    if request.checkpoint:
                        result = self.recovery.paths(
                            request.checkpoint, offset=request.offset
                        )
                    else:
                        result = self.recovery.list(offset=request.offset)
                    yield {
                        "type": "result",
                        "result": {
                            "entries": result,
                            "next_offset": request.offset + len(result),
                        },
                    }
                case Restore():
                    paths = self.recovery.restore(request.checkpoint, request.paths)
                    yield {"type": "result", "result": {"paths": paths}}
                case Write() | Edit() | Bash():
                    if isinstance(request, (Write, Edit)) and self.recovery.excluded(
                        Path(request.path)
                    ):
                        raise ValueError("Target is protected by the sandbox")
                    checkpoint = self.recovery.checkpoint(
                        type(request).__name__.lower()
                    )
                    completed = False
                    try:
                        if stop.is_set():
                            raise RuntimeError("Operation cancelled")
                        yield from self.run(request, stop, lock_fd)
                        completed = True
                    finally:
                        self.recovery.complete(checkpoint, interrupted=not completed)
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

    def __call__(
        self, request: Write | Edit | Bash, stop: threading.Event, lock_fd: int
    ):
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
                + (request.timeout if isinstance(request, Bash) else 300)
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
                # Kill SRT's intermediate shell too; bwrap then kills its PID namespace.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait()
                if process.stdout is not None:
                    process.stdout.close()
