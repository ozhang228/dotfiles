import fcntl
import json
import os
import stat
import sys
import tempfile
import threading
from contextlib import contextmanager
from pathlib import Path

FIELDS = ("defaultProvider", "defaultModel", "defaultThinkingLevel")
ROUTING = FIELDS[:2]
EFFORTS = {"off", "minimal", "low", "medium", "high", "xhigh", "max"}
LIMIT = 256 * 1024


def read_settings(path: Path):
    descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(descriptor, "rb") as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_size > LIMIT:
            raise ValueError("Pi settings must be a regular file of at most 256 KiB")
        content = stream.read(LIMIT + 1)
        if len(content) > LIMIT:
            raise ValueError("Pi settings exceed 256 KiB")
        settings = json.loads(content)
        if not isinstance(settings, dict):
            raise ValueError("Pi settings must be a JSON object")
        return settings, info


def selected_preferences(settings):
    selected = {}
    for field in FIELDS:
        if field not in settings:
            continue
        value = settings[field]
        if (
            not isinstance(value, str)
            or not 1 <= len(value) <= 512
            or any(ord(character) < 32 for character in value)
            or (field == "defaultThinkingLevel" and value not in EFFORTS)
        ):
            raise ValueError(f"Invalid Pi preference: {field}")
        selected[field] = value
    return selected


@contextmanager
def persist_preferences(*, snapshot: Path, source: Path, lock: Path):
    source = source.resolve(strict=True)
    baseline = selected_preferences(read_settings(snapshot)[0])
    stopped = threading.Event()

    def flush():
        selected = selected_preferences(read_settings(snapshot)[0])
        changes = {
            key: value for key, value in selected.items() if baseline.get(key) != value
        }
        if not changes:
            return
        routing_changed = any(key in changes for key in ROUTING)
        if routing_changed:
            if not all(key in selected for key in ROUTING):
                raise ValueError(
                    "Pi model selection requires both defaultProvider and defaultModel"
                )
            changes.update({key: selected[key] for key in ROUTING})
        descriptor = os.open(
            lock, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600
        )
        with os.fdopen(descriptor, "r+b") as guard:
            if not stat.S_ISREG(os.fstat(guard.fileno()).st_mode):
                raise ValueError("Pi preference lock must be a regular file")
            fcntl.flock(guard, fcntl.LOCK_EX)
            current, info = read_settings(source)
            if routing_changed and tuple(current.get(key) for key in ROUTING) not in (
                tuple(baseline.get(key) for key in ROUTING),
                tuple(selected[key] for key in ROUTING),
            ):
                raise RuntimeError(
                    "Pi preference conflict: model routing changed in source settings"
                )
            for key, value in changes.items():
                if current.get(key) not in (baseline.get(key), value):
                    raise RuntimeError(
                        f"Pi preference conflict: {key} changed in source settings"
                    )
            current.update(changes)
            content = json.dumps(current, indent=2, ensure_ascii=False) + "\n"
            if len(content.encode("utf-8")) > LIMIT:
                raise ValueError("Saved Pi settings would exceed 256 KiB")
            descriptor, name = tempfile.mkstemp(
                prefix=".pi-settings-", dir=source.parent
            )
            temporary = Path(name)
            try:
                with os.fdopen(descriptor, "w") as output:
                    os.fchmod(output.fileno(), stat.S_IMODE(info.st_mode))
                    output.write(content)
                    output.flush()
                    os.fsync(output.fileno())
                latest = source.stat(follow_symlinks=False)
                if (latest.st_ino, latest.st_mtime_ns, latest.st_size) != (
                    info.st_ino,
                    info.st_mtime_ns,
                    info.st_size,
                ):
                    raise RuntimeError(
                        "Pi preference conflict: source settings changed during save"
                    )
                os.replace(temporary, source)
            finally:
                temporary.unlink(missing_ok=True)
        baseline.update(changes)

    def watch():
        previous_error = ""
        while not stopped.wait(0.25):
            try:
                flush()
                previous_error = ""
            except json.JSONDecodeError:
                # Pi may be between truncating and completing a settings write.
                continue
            except (OSError, ValueError, RuntimeError) as error:
                explanation = f"Pi preference save failed: {error}"
                if explanation != previous_error:
                    print(explanation, file=sys.stderr)
                previous_error = explanation

    thread = threading.Thread(target=watch, daemon=True)
    thread.start()
    try:
        yield
    finally:
        stopped.set()
        thread.join()
        try:
            flush()
        except (OSError, ValueError, RuntimeError) as error:
            raise RuntimeError(f"Pi preference save failed: {error}") from error
