import fcntl
import io
import json
import os
import sys
import tempfile
import time
from contextlib import redirect_stderr
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from preferences import persist_preferences


def write_settings(path, settings):
    path.write_text(json.dumps(settings))


def wait_for_default(path, *, field, value):
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        if json.loads(path.read_text()).get(field) == value:
            return
        time.sleep(0.01)
    raise AssertionError(f"{field} was not saved while Pi was running")


def test_live_and_final_saves_preserve_symlink_mode_and_unrelated_manual_edits():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        canonical = root / "canonical.json"
        source = root / "settings.json"
        source.symlink_to(canonical)
        snapshot = root / "snapshot.json"
        original = {
            "defaultProvider": "old-provider",
            "defaultModel": "old",
            "defaultThinkingLevel": "medium",
            "extensions": ["!**"],
        }
        write_settings(canonical, original)
        canonical.chmod(0o640)
        write_settings(snapshot, original)
        with persist_preferences(
            snapshot=snapshot, source=source, lock=root / "preferences.lock"
        ):
            manual = {**original, "theme": "cozy"}
            write_settings(canonical, manual)
            write_settings(
                snapshot,
                {
                    **original,
                    "defaultProvider": "new-provider",
                    "defaultModel": "new",
                    "extensions": ["unsafe"],
                    "defaultTools": ["unsafe"],
                },
            )
            wait_for_default(source, field="defaultModel", value="new")
            assert json.loads(source.read_text()) == {
                **manual,
                "defaultProvider": "new-provider",
                "defaultModel": "new",
            }
            write_settings(
                snapshot,
                {
                    **original,
                    "defaultProvider": "new-provider",
                    "defaultModel": "new",
                    "defaultThinkingLevel": "high",
                },
            )
        assert json.loads(source.read_text()) == {
            **manual,
            "defaultProvider": "new-provider",
            "defaultModel": "new",
            "defaultThinkingLevel": "high",
        }
        assert source.is_symlink()
        assert canonical.stat().st_mode & 0o777 == 0o640


def test_two_live_sessions_wait_for_shared_lock_and_merge_independent_defaults():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        source = root / "settings.json"
        snapshots = (root / "first.json", root / "second.json")
        original = {
            "defaultProvider": "foo",
            "defaultModel": "old",
            "defaultThinkingLevel": "medium",
        }
        for path in (source, *snapshots):
            write_settings(path, original)
        with (
            persist_preferences(
                snapshot=snapshots[0], source=source, lock=root / "preferences.lock"
            ),
            persist_preferences(
                snapshot=snapshots[1], source=source, lock=root / "preferences.lock"
            ),
        ):
            with (root / "preferences.lock").open("w") as held:
                fcntl.flock(held, fcntl.LOCK_EX)
                write_settings(snapshots[0], {**original, "defaultModel": "new"})
                write_settings(
                    snapshots[1], {**original, "defaultThinkingLevel": "high"}
                )
                time.sleep(0.35)
                assert json.loads(source.read_text()) == original
            wait_for_default(source, field="defaultModel", value="new")
            wait_for_default(source, field="defaultThinkingLevel", value="high")
        assert json.loads(source.read_text()) == {
            "defaultProvider": "foo",
            "defaultModel": "new",
            "defaultThinkingLevel": "high",
        }


def test_newer_source_default_reports_conflict_and_is_never_overwritten():
    original = {"defaultProvider": "foo", "defaultModel": "gpt"}
    for manual in (
        {"defaultProvider": "foo", "defaultModel": "manual"},
        {"defaultProvider": "bar", "defaultModel": "gpt"},
    ):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "settings.json"
            snapshot = root / "snapshot.json"
            write_settings(source, original)
            write_settings(snapshot, original)
            with pytest.raises(RuntimeError, match="model routing changed in source"):
                with persist_preferences(
                    snapshot=snapshot, source=source, lock=root / "preferences.lock"
                ):
                    write_settings(source, manual)
                    write_settings(
                        snapshot, {"defaultProvider": "foo", "defaultModel": "gpt2"}
                    )
            assert json.loads(source.read_text()) == manual


def test_incomplete_snapshot_is_tolerated_while_running_then_valid_changes_are_saved():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        source = root / "settings.json"
        snapshot = root / "snapshot.json"
        original = {"defaultProvider": "foo", "defaultModel": "old"}
        for path in (source, snapshot):
            write_settings(path, original)
        errors = io.StringIO()
        with redirect_stderr(errors):
            with persist_preferences(
                snapshot=snapshot, source=source, lock=root / "preferences.lock"
            ):
                snapshot.write_text('{"defaultModel":')
                time.sleep(0.35)
                assert json.loads(source.read_text()) == original
                write_settings(snapshot, {**original, "defaultModel": "new"})
                wait_for_default(source, field="defaultModel", value="new")
        assert errors.getvalue() == ""


def test_invalid_or_nonregular_snapshot_is_rejected_without_source_writes():
    for kind in (
        "invalid-effort",
        "non-string",
        "missing-provider",
        "missing-model",
        "malformed",
        "oversized",
        "symlink",
        "fifo",
    ):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "settings.json"
            snapshot = root / "snapshot.json"
            original = '{"defaultModel":"old"}'
            source.write_text(original)
            snapshot.write_text(original)
            with pytest.raises(RuntimeError, match="Pi preference save failed"):
                with persist_preferences(
                    snapshot=snapshot, source=source, lock=root / "preferences.lock"
                ):
                    match kind:
                        case "invalid-effort":
                            write_settings(
                                snapshot,
                                {
                                    "defaultModel": "new",
                                    "defaultThinkingLevel": "invalid",
                                },
                            )
                        case "non-string":
                            write_settings(snapshot, {"defaultModel": ["new"]})
                        case "missing-provider":
                            write_settings(snapshot, {"defaultModel": "new"})
                        case "missing-model":
                            write_settings(snapshot, {"defaultProvider": "new"})
                        case "malformed":
                            snapshot.write_text("{")
                        case "oversized":
                            snapshot.write_text(" " * (256 * 1024 + 1))
                        case "symlink":
                            snapshot.unlink()
                            snapshot.symlink_to(source)
                        case "fifo":
                            snapshot.unlink()
                            os.mkfifo(snapshot)
                        case _:
                            raise AssertionError(kind)
            assert source.read_text() == original
