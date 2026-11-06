"""Host-only, streamed recovery records. Never mount this store into a worker."""

import contextlib
import fcntl
import hashlib
import os
import re
import sqlite3
import stat
import time
import uuid
from collections.abc import Sequence
from pathlib import Path

BUFFER = 1024 * 1024
REPO_LIMIT = 2 * 1024**3
TOTAL_LIMIT = 5 * 1024**3
RECORD_BYTES = 4096


def relative_path(value: str):
    path = Path(value)
    if (
        not value
        or path.is_absolute()
        or any(part in {".", ".."} for part in value.split("/"))
    ):
        raise ValueError("Paths must be relative, without traversal")
    return path


def sync_directory(path: Path):
    descriptor = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


class Recovery:
    def __init__(
        self,
        root: Path,
        *,
        repo: Path,
        protected: Sequence[Path] = (),
        repo_limit=REPO_LIMIT,
        total_limit=TOTAL_LIMIT,
    ):
        self.root = root
        self.repo = repo.resolve(strict=True)
        self.protected = tuple(
            path.relative_to(self.repo)
            for path in protected
            if path.is_relative_to(self.repo)
        ) + (Path(".git"),)
        self.repo_id = hashlib.sha256(os.fsencode(self.repo)).hexdigest()
        self.repo_limit = repo_limit
        self.total_limit = total_limit
        for path in (root, root / "blobs"):
            path.mkdir(parents=True, mode=0o700, exist_ok=True)
            if path.resolve() != path or path.stat().st_uid != os.getuid():
                raise RuntimeError("Recovery store must be private and owned")
            path.chmod(0o700)
        with self.locked() as database:
            database.executescript("""
                CREATE TABLE IF NOT EXISTS checkpoints(id TEXT PRIMARY KEY, repo TEXT, created INTEGER, label TEXT, status TEXT);
                CREATE TABLE IF NOT EXISTS entries(checkpoint TEXT, path TEXT, kind TEXT, mode INTEGER, digest TEXT, target TEXT, bytes INTEGER, PRIMARY KEY(checkpoint,path));
                CREATE TABLE IF NOT EXISTS blobs(digest TEXT PRIMARY KEY, bytes INTEGER);
                CREATE INDEX IF NOT EXISTS repo_history ON checkpoints(repo,created);
                CREATE INDEX IF NOT EXISTS blob_references ON entries(digest);
                CREATE TABLE IF NOT EXISTS exports(checkpoint TEXT, path TEXT, destination TEXT, status TEXT, created INTEGER);
                CREATE INDEX IF NOT EXISTS export_history ON exports(checkpoint,created);
            """)
            # Blob bytes track allocation; entries retain logical file lengths.
            if database.execute("PRAGMA user_version").fetchone()[0] == 0:
                for (digest,) in database.execute("SELECT digest FROM blobs"):
                    allocated = (root / "blobs" / digest).stat().st_blocks * 512
                    database.execute(
                        "UPDATE blobs SET bytes=? WHERE digest=?", (allocated, digest)
                    )
                database.execute("PRAGMA user_version=1")

    @contextlib.contextmanager
    def locked(self):
        with (self.root / "lock").open("a+b") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            database = sqlite3.connect(self.root / "recovery.sqlite")
            try:
                database.execute("PRAGMA synchronous=FULL")
                database.execute("PRAGMA cache_size=-2048")
                database.execute("PRAGMA temp_store=FILE")
                if database.execute("PRAGMA quick_check").fetchone()[0] != "ok":
                    raise RuntimeError("Recovery journal is corrupt; writes refused")
                yield database
                database.commit()
            finally:
                database.close()

    def excluded(self, path: Path):
        return any(
            path == protected or path.is_relative_to(protected)
            for protected in self.protected
        ) or any(
            part in {".pi", ".git"} or part == ".env" or part.startswith(".env.")
            for part in path.parts
        )

    def validate_mounts(self):
        for line in Path("/proc/self/mountinfo").read_text().splitlines():
            mount = Path(
                re.sub(
                    r"\\([0-7]{3})",
                    lambda match: chr(int(match[1], 8)),
                    line.split()[4],
                )
            )
            if mount != self.repo and mount.is_relative_to(self.repo):
                raise RuntimeError(f"Nested mount refused: {mount}")

    def files(self):
        self.validate_mounts()
        descriptor = os.open(self.repo, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        device = os.fstat(descriptor).st_dev

        def walk(parent, prefix):
            with os.scandir(parent) as items:
                for item in items:
                    path = prefix / item.name
                    if self.excluded(path):
                        continue
                    info = os.stat(item.name, dir_fd=parent, follow_symlinks=False)
                    if info.st_dev != device:
                        raise RuntimeError(f"Nested mount refused: {path}")
                    if stat.S_ISDIR(info.st_mode):
                        child = os.open(
                            item.name,
                            os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                            dir_fd=parent,
                        )
                        try:
                            if os.fstat(child).st_ino != info.st_ino:
                                raise RuntimeError(
                                    "Repository changed during checkpoint"
                                )
                            yield (
                                str(path),
                                "directory",
                                stat.S_IMODE(info.st_mode),
                                "",
                                "",
                                0,
                            )
                            yield from walk(child, path)
                        finally:
                            os.close(child)
                    elif stat.S_ISLNK(info.st_mode):
                        target = os.readlink(item.name, dir_fd=parent)
                        yield (
                            str(path),
                            "symlink",
                            stat.S_IMODE(info.st_mode),
                            "",
                            target,
                            0,
                        )
                    elif stat.S_ISREG(info.st_mode):
                        if info.st_nlink != 1:
                            raise RuntimeError(f"Writable hardlink refused: {path}")
                        file = os.open(
                            item.name, os.O_RDONLY | os.O_NOFOLLOW, dir_fd=parent
                        )
                        try:
                            before = os.fstat(file)
                            if before.st_ino != info.st_ino or before.st_nlink != 1:
                                raise RuntimeError(
                                    "Repository changed during checkpoint"
                                )
                            yield (
                                str(path),
                                "file",
                                stat.S_IMODE(info.st_mode),
                                file,
                                "",
                                before.st_size,
                            )
                        finally:
                            os.close(file)
                    else:
                        raise RuntimeError(f"Special file refused: {path}")

        try:
            yield from walk(descriptor, Path())
        finally:
            os.close(descriptor)

    def usage(self, database, repo=None):
        if repo is None:
            # Reserve a complete rollback journal and VACUUM copy alongside the database.
            pages = database.execute("PRAGMA page_count").fetchone()[0]
            page_size = database.execute("PRAGMA page_size").fetchone()[0]
            blobs = database.execute(
                "SELECT coalesce(sum(bytes),0) FROM blobs"
            ).fetchone()[0]
            database_bytes = max(
                pages * page_size,
                (self.root / "recovery.sqlite").stat().st_blocks * 512,
            )
            directories = sum(
                path.stat().st_blocks * 512 for path in (self.root, self.root / "blobs")
            )
            return database_bytes * 3 + blobs + directories
        metadata = database.execute(
            "SELECT coalesce(sum(512 + length(CAST(path AS BLOB)) + length(CAST(target AS BLOB))),0) FROM entries WHERE checkpoint IN (SELECT id FROM checkpoints WHERE repo=?)",
            (repo,),
        ).fetchone()[0]
        blobs = database.execute(
            "SELECT coalesce(sum(bytes),0) FROM blobs b WHERE EXISTS (SELECT 1 FROM entries e JOIN checkpoints c ON c.id=e.checkpoint WHERE c.repo=? AND e.digest=b.digest)",
            (repo,),
        ).fetchone()[0]
        records = database.execute(
            "SELECT count(*) FROM checkpoints WHERE repo=?", (repo,)
        ).fetchone()[0]
        exports = database.execute(
            "SELECT coalesce(sum(512 + length(CAST(path AS BLOB)) + length(CAST(destination AS BLOB))),0) FROM exports WHERE checkpoint IN (SELECT id FROM checkpoints WHERE repo=?)",
            (repo,),
        ).fetchone()[0]
        return metadata + blobs + exports + records * RECORD_BYTES

    def collect(self, database, *, pinned_digest="", staging=""):
        for (digest,) in database.execute(
            "SELECT digest FROM blobs b WHERE NOT EXISTS (SELECT 1 FROM entries e WHERE e.digest=b.digest)"
        ):
            if digest == pinned_digest:
                continue
            (self.root / "blobs" / digest).unlink(missing_ok=True)
            database.execute("DELETE FROM blobs WHERE digest=?", (digest,))
        for path in (self.root / "blobs").iterdir():
            if path.name == staging:
                continue
            if not database.execute(
                "SELECT 1 FROM blobs WHERE digest=?", (path.name,)
            ).fetchone():
                path.unlink()

    def make_room(
        self,
        database,
        *,
        repo_bytes: int,
        total_bytes: int,
        digest="",
        size=0,
        staging="",
    ):
        while True:
            repo_blob = (
                size
                if digest
                and not database.execute(
                    "SELECT 1 FROM entries e JOIN checkpoints c ON c.id=e.checkpoint WHERE c.repo=? AND e.digest=? LIMIT 1",
                    (self.repo_id, digest),
                ).fetchone()
                else 0
            )
            total_blob = (
                size
                if digest
                and not database.execute(
                    "SELECT 1 FROM blobs WHERE digest=?", (digest,)
                ).fetchone()
                else 0
            )
            repo_full = (
                self.usage(database, self.repo_id) + repo_bytes + repo_blob
                > self.repo_limit
            )
            if (
                not repo_full
                and self.usage(database) + total_bytes + total_blob <= self.total_limit
            ):
                return
            row = database.execute(
                """SELECT id FROM checkpoints c WHERE status IN ('completed','interrupted')
                AND id NOT IN (SELECT id FROM checkpoints n WHERE n.repo=c.repo AND n.status != 'staging' ORDER BY created DESC LIMIT 1)
                """
                + (" AND repo=?" if repo_full else "")
                + " ORDER BY created LIMIT 1",
                (self.repo_id,) if repo_full else (),
            ).fetchone()
            if row is None:
                raise RuntimeError(
                    "Recovery storage limit cannot fit a protected checkpoint"
                )
            database.execute("DELETE FROM exports WHERE checkpoint=?", row)
            database.execute("DELETE FROM entries WHERE checkpoint=?", row)
            database.execute("DELETE FROM checkpoints WHERE id=?", row)
            database.commit()
            self.collect(database, pinned_digest=digest, staging=staging)
            database.commit()
            database.execute("VACUUM")

    def checkpoint(self, label: str):
        identifier = uuid.uuid4().hex
        with self.locked() as database:
            # A creator holds this global lock until staging becomes active.
            # Any staging record visible here belongs to a dead creator, in any repo.
            database.execute(
                "DELETE FROM entries WHERE checkpoint IN (SELECT id FROM checkpoints WHERE status='staging')"
            )
            database.execute("DELETE FROM checkpoints WHERE status='staging'")
            database.commit()
            self.collect(database)
            database.commit()
            try:
                self.make_room(
                    database, repo_bytes=RECORD_BYTES, total_bytes=RECORD_BYTES
                )
                database.execute(
                    "INSERT INTO checkpoints VALUES(?,?,?,?,?)",
                    (identifier, self.repo_id, time.time_ns(), label[:120], "staging"),
                )
                fragment = os.statvfs(self.root / "blobs").f_frsize
                for path, kind, mode, file, target, size in self.files():
                    cost = 512 + len(path.encode()) + len(target.encode())
                    digest = ""
                    new_blob = False
                    blob = None
                    before = None
                    if kind == "file":
                        before = os.fstat(file)
                        hasher = hashlib.sha256()
                        copied = 0
                        while chunk := os.read(file, BUFFER):
                            copied += len(chunk)
                            if copied > size:
                                raise RuntimeError("File changed during checkpoint")
                            hasher.update(chunk)
                        after = os.fstat(file)

                        def fingerprint(info):
                            return (
                                info.st_ino,
                                info.st_size,
                                info.st_mtime_ns,
                                info.st_ctime_ns,
                            )

                        if fingerprint(before) != fingerprint(after) or copied != size:
                            raise RuntimeError("File changed during checkpoint")
                        digest = hasher.hexdigest()
                        blob = database.execute(
                            "SELECT bytes FROM blobs WHERE digest=?", (digest,)
                        ).fetchone()
                        new_blob = blob is None
                    allocation = (
                        blob[0]
                        if blob
                        else ((size + fragment - 1) // fragment) * fragment
                    )
                    if (
                        cost + allocation + RECORD_BYTES > self.repo_limit
                        or cost + allocation > self.total_limit
                    ):
                        raise RuntimeError(
                            "Required checkpoint exceeds recovery storage limit"
                        )
                    self.make_room(
                        database,
                        repo_bytes=cost,
                        total_bytes=max(cost * 2, 65536),
                        digest=digest,
                        size=allocation,
                    )
                    if new_blob:
                        staging = self.root / "blobs" / f".{identifier}"
                        os.lseek(file, 0, os.SEEK_SET)
                        copied = 0
                        hasher = hashlib.sha256()
                        with staging.open("xb") as output:
                            while chunk := os.read(file, BUFFER):
                                copied += len(chunk)
                                if copied > size:
                                    raise RuntimeError("File changed during checkpoint")
                                hasher.update(chunk)
                                output.write(chunk)
                                output.flush()
                                allocated = os.fstat(output.fileno()).st_blocks * 512
                                if allocated > allocation:
                                    allocation = allocated
                                    self.make_room(
                                        database,
                                        repo_bytes=cost,
                                        total_bytes=max(cost * 2, 65536),
                                        digest=digest,
                                        size=allocation,
                                        staging=staging.name,
                                    )
                            os.fsync(output.fileno())
                            allocation = os.fstat(output.fileno()).st_blocks * 512
                            self.make_room(
                                database,
                                repo_bytes=cost,
                                total_bytes=max(cost * 2, 65536),
                                digest=digest,
                                size=allocation,
                                staging=staging.name,
                            )
                        if hasher.hexdigest() != digest or copied != size:
                            raise RuntimeError("File changed during checkpoint")
                        staging.rename(self.root / "blobs" / digest)
                        sync_directory(staging.parent)
                        database.execute(
                            "INSERT INTO blobs VALUES(?,?)", (digest, allocation)
                        )
                    database.execute(
                        "INSERT INTO entries VALUES(?,?,?,?,?,?,?)",
                        (identifier, path, kind, mode, digest, target, size),
                    )
                database.execute(
                    'UPDATE checkpoints SET status="active" WHERE id=?', (identifier,)
                )
                database.commit()
                sync_directory(self.root)
                return identifier
            except BaseException:
                database.rollback()
                database.execute(
                    "DELETE FROM entries WHERE checkpoint=?", (identifier,)
                )
                database.execute("DELETE FROM checkpoints WHERE id=?", (identifier,))
                database.commit()
                self.collect(database)
                database.commit()
                raise

    def complete(self, checkpoint: str, *, interrupted=False):
        with self.locked() as database:
            database.execute(
                "UPDATE checkpoints SET status=? WHERE id=? AND repo=?",
                (
                    "interrupted" if interrupted else "completed",
                    checkpoint,
                    self.repo_id,
                ),
            )

    def list(self, *, offset=0, limit=20):
        with self.locked() as database:
            return [
                dict(
                    zip(
                        ("checkpoint", "label", "status", "files", "last_recovery"),
                        row,
                        strict=True,
                    )
                )
                for row in database.execute(
                    """SELECT id,label,status,(SELECT count(*) FROM entries WHERE checkpoint=c.id), (SELECT status FROM exports WHERE checkpoint=c.id ORDER BY created DESC LIMIT 1) FROM checkpoints c WHERE repo=? AND status != 'staging' ORDER BY created DESC LIMIT ? OFFSET ?""",
                    (self.repo_id, min(limit, 50), offset),
                )
            ]

    def paths(self, checkpoint: str, *, offset=0):
        with self.locked() as database:
            if not database.execute(
                "SELECT 1 FROM checkpoints WHERE id=? AND repo=?",
                (checkpoint, self.repo_id),
            ).fetchone():
                raise ValueError("Unknown checkpoint")
            return [
                dict(zip(("path", "kind", "bytes"), row, strict=True))
                for row in database.execute(
                    "SELECT path,kind,bytes FROM entries WHERE checkpoint=? ORDER BY path LIMIT 50 OFFSET ?",
                    (checkpoint, offset),
                )
            ]

    def restore(self, checkpoint: str, paths: Sequence[str]):
        if not 1 <= len(paths) <= 50:
            raise ValueError("Recover 1 to 50 selected paths")
        selection = tuple(relative_path(path) for path in paths)
        self.validate_mounts()
        with self.locked() as database:
            if not database.execute(
                "SELECT 1 FROM checkpoints WHERE id=? AND repo=?",
                (checkpoint, self.repo_id),
            ).fetchone():
                raise ValueError("Unknown checkpoint")
            rows = []
            for path in selection:
                row = database.execute(
                    "SELECT kind,mode,digest,target FROM entries WHERE checkpoint=? AND path=?",
                    (checkpoint, str(path)),
                ).fetchone()
                if row is None or row[0] == "directory" or self.excluded(path):
                    raise ValueError("Selected file is not in checkpoint")
                rows.append(row)
            # Pin the source across reservations and interrupted multi-file exports.
            database.execute(
                'UPDATE checkpoints SET status="recovering" WHERE id=?', (checkpoint,)
            )
            database.commit()
            database.execute(
                'DELETE FROM exports WHERE checkpoint=? AND status="completed" AND created NOT IN (SELECT created FROM exports WHERE checkpoint=? ORDER BY created DESC LIMIT 50)',
                (checkpoint, checkpoint),
            )
            database.commit()
            estimated = sum(1024 + len(str(path).encode()) * 2 for path in selection)
            self.make_room(
                database, repo_bytes=estimated, total_bytes=max(estimated * 2, 65536)
            )
            restored = []
            for path, (kind, mode, digest, target) in zip(selection, rows, strict=True):
                parent = os.open(
                    self.repo, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
                )
                try:
                    device = os.fstat(parent).st_dev
                    for part in path.parts[:-1]:
                        try:
                            os.mkdir(part, mode=0o700, dir_fd=parent)
                        except FileExistsError:
                            pass
                        child = os.open(
                            part,
                            os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                            dir_fd=parent,
                        )
                        if os.fstat(child).st_dev != device:
                            os.close(child)
                            raise RuntimeError(f"Nested mount refused: {path}")
                        os.close(parent)
                        parent = child
                    name = path.name
                    record = time.time_ns()
                    database.execute(
                        "INSERT INTO exports VALUES(?,?,?,?,?)",
                        (checkpoint, str(path), "", "interrupted", record),
                    )
                    database.commit()
                    try:
                        if kind == "file":
                            descriptor = os.open(
                                name,
                                os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                                mode,
                                dir_fd=parent,
                            )
                        else:
                            os.symlink(target, name, dir_fd=parent)
                            descriptor = None
                    except FileExistsError:
                        # Existing host files are never replaced: no compare/rename race.
                        name = f"{path.name}.recovered-{checkpoint[:8]}-{uuid.uuid4().hex[:8]}"
                        if kind == "file":
                            descriptor = os.open(
                                name,
                                os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                                mode,
                                dir_fd=parent,
                            )
                        else:
                            os.symlink(target, name, dir_fd=parent)
                            descriptor = None
                    database.execute(
                        "UPDATE exports SET destination=? WHERE checkpoint=? AND created=?",
                        (str(path.parent / name), checkpoint, record),
                    )
                    database.commit()
                    if descriptor is not None:
                        with (
                            os.fdopen(descriptor, "wb") as output,
                            (self.root / "blobs" / digest).open("rb") as source,
                        ):
                            hasher = hashlib.sha256()
                            while chunk := source.read(BUFFER):
                                hasher.update(chunk)
                                output.write(chunk)
                            if hasher.hexdigest() != digest:
                                raise RuntimeError(
                                    "Recovery blob is corrupt; partial export retained"
                                )
                            output.flush()
                            os.fchmod(output.fileno(), mode & 0o777)
                            os.fsync(output.fileno())
                    os.fsync(parent)
                    database.execute(
                        'UPDATE exports SET status="completed" WHERE checkpoint=? AND created=?',
                        (checkpoint, record),
                    )
                    database.commit()
                    restored.append(str(path.parent / name))
                finally:
                    os.close(parent)
            database.execute(
                'UPDATE checkpoints SET status="completed" WHERE id=?', (checkpoint,)
            )
            return restored
