import contextlib
import multiprocessing
import os
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from recovery import BUFFER, Recovery


def interrupt_export(root, repo, checkpoint):
    fdopen = os.fdopen

    @contextlib.contextmanager
    def interrupted_output(descriptor, mode):
        with fdopen(descriptor, mode) as output:
            write = output.write

            def write_and_exit(chunk):
                write(chunk)
                output.flush()
                os.fsync(output.fileno())
                os._exit(23)

            with patch.object(output, "write", side_effect=write_and_exit):
                yield output

    with patch("recovery.os.fdopen", interrupted_output):
        Recovery(root, repo=repo).restore(checkpoint, ["file"])


def interrupt_checkpoint(root, repo):
    with patch("recovery.sync_filesystem", side_effect=lambda _: os._exit(23)):
        Recovery(root, repo=repo).checkpoint("bash")


@pytest.mark.parametrize("failure", ["io-error", "legacy-io-error", "crash"])
def test_failed_durability_barrier_preserves_previous_checkpoint(failure):
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        (repo / "file").write_bytes(b"original")
        store = Recovery(root / "private", repo=repo)
        previous = store.checkpoint("bash")
        store.complete(previous)
        (repo / "file").write_bytes(b"replacement")
        (repo / "ignored").write_bytes(b"new ignored bytes")
        if failure in {"io-error", "legacy-io-error"}:
            kernel = os.uname()
            reported_kernel = (
                os.uname_result(
                    (
                        kernel.sysname,
                        kernel.nodename,
                        "5.4.0",
                        kernel.version,
                        kernel.machine,
                    )
                )
                if failure == "legacy-io-error"
                else kernel
            )
            barrier = "os.fsync" if failure == "legacy-io-error" else "sync_filesystem"
            with (
                patch("recovery.os.uname", return_value=reported_kernel),
                patch(f"recovery.{barrier}", side_effect=OSError("disk failure")),
            ):
                with pytest.raises(OSError, match="disk failure"):
                    store.checkpoint("bash")
        else:
            process = multiprocessing.get_context("spawn").Process(
                target=interrupt_checkpoint, args=(root / "private", repo)
            )
            process.start()
            try:
                process.join(timeout=10)
                assert process.exitcode == 23
            finally:
                if process.is_alive():
                    process.kill()
                    process.join(timeout=5)
                process.close()
        restarted = Recovery(root / "private", repo=repo)
        assert [entry["checkpoint"] for entry in restarted.list()] == [previous]
        restored = restarted.restore(previous, ["file"])
        assert (repo / restored[0]).read_bytes() == b"original"
        assert (repo / "file").read_bytes() == b"replacement"
        replacement = restarted.checkpoint("bash")
        restarted.complete(replacement)
        (repo / "file").unlink()
        (repo / "ignored").unlink()
        restarted.restore(replacement, ["file", "ignored"])
        assert (repo / "file").read_bytes() == b"replacement"
        assert (repo / "ignored").read_bytes() == b"new ignored bytes"


def test_interrupted_export_retains_partial_bytes_and_recovers_complete_sibling():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        original = b"original" * (BUFFER // 4)
        (repo / "file").write_bytes(original)
        store = Recovery(root / "private", repo=repo)
        checkpoint = store.checkpoint("bash")
        store.complete(checkpoint)
        (repo / "file").unlink()
        process = multiprocessing.get_context("spawn").Process(
            target=interrupt_export, args=(root / "private", repo, checkpoint)
        )
        process.start()
        try:
            process.join(timeout=10)
            assert process.exitcode == 23
        finally:
            if process.is_alive():
                process.kill()
                process.join(timeout=5)
            process.close()
        assert (repo / "file").read_bytes() == original[:BUFFER]
        restarted = Recovery(root / "private", repo=repo)
        assert restarted.list()[0]["last_recovery"] == "interrupted"
        restored = restarted.restore(checkpoint, ["file"])
        assert restored[0].startswith("file.recovered-")
        assert (repo / restored[0]).read_bytes() == original
        assert (repo / "file").read_bytes() == original[:BUFFER]
        assert restarted.list()[0]["status"] == "completed"


def test_delayed_allocation_counts_saved_bytes_and_refuses_oversized_capture():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        (repo / "original").write_bytes(b"original")
        store = Recovery(root / "private", repo=repo, repo_limit=40000)
        previous = store.checkpoint("bash")
        store.complete(previous)
        (repo / "first").write_bytes(b"a" * 16384)
        fstat, fsync = os.fstat, os.fsync
        persisted = set()

        def delayed_blocks(descriptor):
            info = fstat(descriptor)
            path = Path(os.readlink(f"/proc/self/fd/{descriptor}"))
            if (
                path.parent == root / "private/blobs"
                and path.name.startswith(".")
                and info.st_ino not in persisted
            ):
                return SimpleNamespace(st_blocks=0)
            return info

        def persist(descriptor):
            fsync(descriptor)
            persisted.add(fstat(descriptor).st_ino)

        with (
            patch("recovery.os.fstat", delayed_blocks),
            patch("recovery.os.fsync", persist),
        ):
            latest = store.checkpoint("bash")
            store.complete(latest)
            (repo / "second").write_bytes(b"b" * 16384)
            with pytest.raises(RuntimeError, match="storage limit"):
                store.checkpoint("bash")
        assert store.list()[0]["checkpoint"] == latest
        (repo / "first").unlink()
        store.restore(latest, ["first"])
        assert (repo / "first").read_bytes() == b"a" * 16384
        assert (repo / "second").read_bytes() == b"b" * 16384


@pytest.mark.parametrize("phase", ["hash", "copy"])
def test_host_edit_during_capture_refuses_checkpoint_and_preserves_previous(phase):
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        target = repo / "file"
        original = b"a" * (BUFFER * 2)
        target.write_bytes(original)
        store = Recovery(root / "private", repo=repo)
        checkpoint = store.checkpoint("bash")
        store.complete(checkpoint)
        target.write_bytes(b"b" * len(original))
        host_bytes = b"c" * len(original)
        read = os.read
        seek = os.lseek
        edited = False

        def edit_during_read(descriptor, size):
            nonlocal edited
            chunk = read(descriptor, size)
            if chunk and not edited:
                edited = True
                target.write_bytes(host_bytes)
            return chunk

        def edit_before_copy(descriptor, offset, whence):
            target.write_bytes(host_bytes)
            return seek(descriptor, offset, whence)

        boundary = "os.read" if phase == "hash" else "os.lseek"
        race = edit_during_read if phase == "hash" else edit_before_copy
        with patch(f"recovery.{boundary}", race):
            with pytest.raises(RuntimeError, match="File changed during checkpoint"):
                store.checkpoint("bash")
        restarted = Recovery(root / "private", repo=repo)
        assert [entry["checkpoint"] for entry in restarted.list()] == [checkpoint]
        assert target.read_bytes() == host_bytes
        restored = restarted.restore(checkpoint, ["file"])
        assert (repo / restored[0]).read_bytes() == original
        assert target.read_bytes() == host_bytes
        replacement = restarted.checkpoint("bash")
        restarted.complete(replacement)
        target.unlink()
        restarted.restore(replacement, ["file"])
        assert target.read_bytes() == host_bytes


def test_interrupted_command_preserves_ignored_untracked_and_uncommitted_bytes():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        (repo / ".git").mkdir()
        (repo / "config.py").write_bytes(b"uncommitted\x00bytes")
        (repo / "notes.md").write_text("untracked")
        (repo / "ignored").write_text("ignored")
        store = Recovery(root / "private", repo=repo)
        checkpoint = store.checkpoint("bash")
        (repo / "config.py").write_text("damaged")
        (repo / "notes.md").unlink()
        restarted = Recovery(root / "private", repo=repo)
        restored = restarted.restore(checkpoint, ["config.py", "notes.md", "ignored"])
        assert (repo / restored[0]).read_bytes() == b"uncommitted\x00bytes"
        assert (repo / "config.py").read_text() == "damaged"
        assert (repo / "notes.md").read_text() == "untracked"
        assert (repo / restored[2]).read_text() == "ignored"
        assert restarted.list()[0]["status"] == "completed"


def test_storage_prunes_oldest_completed_but_oversized_checkpoint_never_mutates():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        (repo / "file").write_bytes(b"a" * 5000)
        store = Recovery(
            root / "private", repo=repo, repo_limit=30000, total_limit=400000
        )
        first = store.checkpoint("write")
        store.complete(first)
        (repo / "file").write_bytes(b"b" * 5000)
        second = store.checkpoint("write")
        store.complete(second)
        (repo / "file").write_bytes(b"c" * 5000)
        third = store.checkpoint("write")
        store.complete(third)
        (repo / "file").write_bytes(b"d" * 5000)
        fourth = store.checkpoint("write")
        store.complete(fourth)
        assert first not in [entry["checkpoint"] for entry in store.list()]
        recovered = store.restore(fourth, ["file"])
        assert (repo / recovered[0]).read_bytes() == b"d" * 5000
        (repo / "file").write_bytes(b"x" * 100000)
        with pytest.raises(RuntimeError, match="limit"):
            store.checkpoint("write")
        assert (repo / "file").read_bytes() == b"x" * 100000


def test_snapshot_saves_hardlinks_and_restore_rejects_external_symlink():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        outside = root / "outside"
        outside.mkdir()
        (repo / "file").write_text("safe")
        (repo / "dir").mkdir()
        (repo / "dir/file").write_text("nested")
        store = Recovery(root / "private", repo=repo)
        checkpoint = store.checkpoint("write")
        (root / "hardlink").hardlink_to(repo / "file")
        shared = store.checkpoint("bash")
        recovered = store.restore(shared, ["file"])
        assert (repo / recovered[0]).read_text() == "safe"
        assert (root / "hardlink").read_text() == "safe"
        assert (repo / "file").stat().st_nlink == 2
        (root / "hardlink").unlink()
        (repo / "dir/file").unlink()
        (repo / "dir").rmdir()
        (repo / "dir").symlink_to(outside, target_is_directory=True)
        with pytest.raises(OSError):
            store.restore(checkpoint, ["dir/file"])
        assert list(outside.iterdir()) == []


def test_checkpoint_collects_orphans_across_multiple_lookup_batches():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        for index in range(257):
            (repo / f"file-{index}").write_text(f"saved-{index}")
        store = Recovery(root / "private", repo=repo)
        first = store.checkpoint("write")
        store.complete(first)
        orphans = [store.root / "blobs" / name for name in (".crashed-a", ".crashed-b")]
        for path in orphans:
            path.write_text("unfinished capture")
        latest = store.checkpoint("write")
        store.complete(latest)
        assert all(not path.exists() for path in orphans)
        for name in ("file-0", "file-256"):
            (repo / name).unlink()
        assert store.restore(latest, ["file-0", "file-256"]) == ["file-0", "file-256"]
        assert (repo / "file-0").read_text() == "saved-0"
        assert (repo / "file-256").read_text() == "saved-256"


def test_unchanged_large_content_is_stored_once_across_checkpoints():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        (repo / "large").write_bytes(b"saved" * 20000)
        (repo / "empty").touch()
        store = Recovery(
            root / "private", repo=repo, repo_limit=120000, total_limit=1000000
        )
        first = store.checkpoint("bash")
        store.complete(first)
        second = store.checkpoint("bash")
        store.complete(second)
        assert [entry["checkpoint"] for entry in store.list()] == [second, first]
        assert len(list((root / "private/blobs").iterdir())) == 2
        (repo / "large").unlink()
        store.restore(first, ["large", "empty"])
        assert (repo / "large").read_bytes() == b"saved" * 20000


def test_failed_replacement_keeps_latest_checkpoint_and_reused_pruned_blob():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        store = Recovery(
            root / "private", repo=repo, repo_limit=28000, total_limit=1000000
        )
        (repo / "file").write_bytes(b"old" * 2000)
        first = store.checkpoint("bash")
        store.complete(first)
        (repo / "file").write_bytes(b"latest" * 1000)
        latest = store.checkpoint("bash")
        store.complete(latest)
        (repo / "file").write_bytes(b"old" * 2000)
        reused = store.checkpoint("bash")
        store.complete(reused)
        assert first not in [entry["checkpoint"] for entry in store.list()]
        recovered = store.restore(reused, ["file"])
        assert (repo / recovered[0]).read_bytes() == b"old" * 2000
        (repo / "file").write_bytes(b"oversized" * 10000)
        with pytest.raises(RuntimeError, match="limit"):
            store.checkpoint("bash")
        assert reused in [entry["checkpoint"] for entry in store.list()]
        recovered = store.restore(reused, ["file"])
        assert (repo / recovered[0]).read_bytes() == b"old" * 2000


def test_recovery_never_follows_an_intermediate_parent_symlink():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        (repo / "a/b").mkdir(parents=True)
        (repo / "a/b/file").write_text("saved")
        store = Recovery(root / "private", repo=repo)
        checkpoint = store.checkpoint("bash")
        (repo / "a/b/file").unlink()
        (repo / "a/b").rmdir()
        (repo / "a").rmdir()
        (root / "outside/b").mkdir(parents=True)
        (repo / "a").symlink_to(root / "outside", target_is_directory=True)
        with pytest.raises(OSError):
            store.restore(checkpoint, ["a/b/file"])
        assert list((root / "outside/b").iterdir()) == []


def test_restore_salvages_selected_files_despite_unrelated_unsupported_damage():
    import os

    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        (repo / "important").write_text("original")
        store = Recovery(root / "private", repo=repo)
        checkpoint = store.checkpoint("bash")
        (repo / "important").unlink()
        os.mkfifo(repo / "pipe")
        (repo / "damaged").write_text("unrelated")
        (root / "hardlink").hardlink_to(repo / "damaged")
        (repo / "unreadable").write_text("private")
        (repo / "unreadable").chmod(0)
        assert store.restore(checkpoint, ["important"]) == ["important"]
        assert (repo / "important").read_text() == "original"
        assert (repo / "damaged").read_text() == "unrelated"
        (repo / "unreadable").chmod(0o600)
        with pytest.raises(RuntimeError, match="refused"):
            store.checkpoint("bash")


def test_tiny_distinct_files_are_charged_for_allocated_blocks():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        (repo / "original").write_text("saved")
        store = Recovery(root / "private", repo=repo, total_limit=3_000_000)
        latest = store.checkpoint("bash")
        store.complete(latest)
        for index in range(1000):
            (repo / f"tiny-{index}").write_text(str(index))
        with pytest.raises(RuntimeError, match="limit"):
            store.checkpoint("bash")
        assert [entry["checkpoint"] for entry in store.list()] == [latest]
        (repo / "original").unlink()
        assert store.restore(latest, ["original"]) == ["original"]
        assert (repo / "original").read_text() == "saved"
        allocated = (root / "private").stat().st_blocks * 512 + sum(
            path.stat().st_blocks * 512 for path in (root / "private").rglob("*")
        )
        assert allocated <= 3_000_000


def test_deduplicated_files_still_enforce_global_metadata_limit():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        (repo / "original").write_text("saved")
        store = Recovery(root / "private", repo=repo, total_limit=300000)
        latest = store.checkpoint("bash")
        store.complete(latest)
        for index in range(1000):
            (repo / f"duplicate-{index}").write_text("same")
        with pytest.raises(RuntimeError, match="storage limit"):
            store.checkpoint("bash")
        assert [entry["checkpoint"] for entry in store.list()] == [latest]
        (repo / "original").unlink()
        assert store.restore(latest, ["original"]) == ["original"]
        assert (repo / "original").read_text() == "saved"
        allocated = (root / "private").stat().st_blocks * 512 + sum(
            path.stat().st_blocks * 512 for path in (root / "private").rglob("*")
        )
        assert allocated <= 300000


def test_legacy_store_migrates_quota_without_changing_saved_file_lengths():
    import sqlite3

    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        (repo / "file").write_text("saved")
        store = Recovery(root / "private", repo=repo)
        checkpoint = store.checkpoint("bash")
        store.complete(checkpoint)
        with sqlite3.connect(root / "private/recovery.sqlite") as database:
            database.execute("UPDATE blobs SET bytes=5")
            database.execute("PRAGMA user_version=0")
        restarted = Recovery(root / "private", repo=repo, repo_limit=12000)
        with pytest.raises(RuntimeError, match="limit"):
            restarted.checkpoint("bash")
        assert restarted.paths(checkpoint) == [
            {"path": "file", "kind": "file", "bytes": 5}
        ]
        (repo / "file").unlink()
        assert restarted.restore(checkpoint, ["file"]) == ["file"]
        assert (repo / "file").read_text() == "saved"


def test_abrupt_prune_crash_in_another_repo_does_not_strand_global_quota():
    import sqlite3
    import subprocess
    import textwrap

    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo_a = root / "a"
        repo_b = root / "b"
        repo_a.mkdir()
        repo_b.mkdir()
        store_a = Recovery(root / "private", repo=repo_a, total_limit=500000)
        (repo_a / "file").write_bytes(b"old" * 26000)
        oldest = store_a.checkpoint("bash")
        store_a.complete(oldest)
        (repo_a / "file").write_bytes(b"latest" * 13000)
        latest = store_a.checkpoint("bash")
        store_a.complete(latest)
        (repo_a / "file").write_bytes(b"staged" * 13000)
        (repo_a / "extra").write_bytes(b"extra" * 16000)
        script = textwrap.dedent("""
            import os, sqlite3, sys
            from pathlib import Path
            sys.path.insert(0, sys.argv[1])
            from recovery import Recovery
            connect = sqlite3.connect
            class CrashAfterPrune(sqlite3.Connection):
                def commit(self):
                    super().commit()
                    staged = self.execute("SELECT id FROM checkpoints WHERE status='staging'").fetchone()
                    if staged and self.execute("SELECT 1 FROM entries WHERE checkpoint=?", staged).fetchone() and not self.execute("SELECT 1 FROM checkpoints WHERE id=?", (sys.argv[4],)).fetchone():
                        os._exit(73)
            sqlite3.connect = lambda *args, **kwargs: connect(*args, **kwargs, factory=CrashAfterPrune)
            store = Recovery(Path(sys.argv[2]), repo=Path(sys.argv[3]), total_limit=500000)
            files = store.files
            def ordered_files(**kwargs):
                for entry in files(**kwargs):
                    if entry[0] == 'file':
                        yield entry
                for entry in files(**kwargs):
                    if entry[0] != 'file':
                        yield entry
            store.files = ordered_files
            store.checkpoint('bash')
        """)
        crashed = subprocess.run(
            [
                sys.executable,
                "-c",
                script,
                str(Path(__file__).resolve().parents[1]),
                str(root / "private"),
                str(repo_a),
                oldest,
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        assert crashed.returncode == 73, crashed.stderr
        with sqlite3.connect(root / "private/recovery.sqlite") as database:
            assert (
                database.execute(
                    "SELECT count(*) FROM entries WHERE checkpoint IN (SELECT id FROM checkpoints WHERE status='staging')"
                ).fetchone()[0]
                == 1
            )
        (repo_b / "file").write_bytes(b"other" * 32000)
        store_b = Recovery(root / "private", repo=repo_b, total_limit=500000)
        checkpoint_b = store_b.checkpoint("bash")
        store_b.complete(checkpoint_b)
        assert [entry["checkpoint"] for entry in store_a.list()] == [latest]
        (repo_a / "file").unlink()
        assert store_a.restore(latest, ["file"]) == ["file"]
        assert (repo_a / "file").read_bytes() == b"latest" * 13000


def test_global_pruning_retains_cross_repo_shared_blobs_without_duplicate_charges():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo_a = root / "a"
        repo_b = root / "b"
        repo_a.mkdir()
        repo_b.mkdir()
        store_a = Recovery(root / "private", repo=repo_a, total_limit=420000)
        (repo_a / "file").write_bytes(b"old" * 26000)
        (repo_a / "shared").write_bytes(b"shared" * 3000)
        oldest = store_a.checkpoint("bash")
        store_a.complete(oldest)
        (repo_a / "file").write_bytes(b"latest" * 13000)
        (repo_a / "shared").unlink()
        latest_a = store_a.checkpoint("bash")
        store_a.complete(latest_a)
        store_b = Recovery(
            root / "private", repo=repo_b, repo_limit=126000, total_limit=420000
        )
        (repo_b / "shared").write_bytes(b"shared" * 3000)
        first_b = store_b.checkpoint("bash")
        store_b.complete(first_b)
        (repo_b / "duplicate").write_bytes(b"shared" * 3000)
        (repo_b / "new").write_bytes(b"other" * 16000)
        latest_b = store_b.checkpoint("bash")
        store_b.complete(latest_b)
        assert [entry["checkpoint"] for entry in store_a.list()] == [latest_a]
        assert [entry["checkpoint"] for entry in store_b.list()] == [latest_b, first_b]
        (repo_b / "shared").unlink()
        (repo_b / "new").unlink()
        assert store_b.restore(latest_b, ["shared", "new"]) == ["shared", "new"]
        assert (repo_b / "shared").read_bytes() == b"shared" * 3000
        assert (repo_b / "new").read_bytes() == b"other" * 16000
        (repo_a / "file").unlink()
        assert store_a.restore(latest_a, ["file"]) == ["file"]
        assert (repo_a / "file").read_bytes() == b"latest" * 13000
        allocated = (root / "private").stat().st_blocks * 512 + sum(
            path.stat().st_blocks * 512 for path in (root / "private").rglob("*")
        )
        assert allocated <= 420000
