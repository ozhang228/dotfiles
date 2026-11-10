import http.client
import os
import socket
import sys
import tempfile
import threading
from pathlib import Path
from unittest.mock import Mock, patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from catalog import CatalogCache


def test_cached_catalog_survives_restart_and_returns_before_slow_refresh():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        body = b'{"data":[{"id":"@azure/example"}]}'
        upstream = Mock(spec=http.client.HTTPConnection)
        upstream.getresponse.return_value = Mock(status=200)
        upstream.getresponse.return_value.read.return_value = body
        cache = CatalogCache(
            root / "catalog", key="first-key", connect=lambda host: upstream
        )
        assert cache.get(host="ai.drwcloud.com", path="/v1/models") == (200, body)
        entered = threading.Event()
        release = threading.Event()
        finished = threading.Event()

        def offline_request(*args, **kwargs):
            entered.set()
            if not release.wait(5):
                raise RuntimeError("Refresh was not released")
            raise socket.timeout()

        offline = Mock(spec=http.client.HTTPConnection)
        offline.request.side_effect = offline_request
        offline.close.side_effect = finished.set
        restarted = CatalogCache(
            root / "catalog", key="first-key", connect=lambda host: offline
        )
        try:
            assert restarted.get(host="ai.drwcloud.com", path="/v1/models") == (
                200,
                body,
            )
            assert entered.wait(2)
            assert not release.is_set()
        finally:
            release.set()
            assert finished.wait(2)
        assert (
            restarted.read(
                restarted.path(host="ai.drwcloud.com", path="/v1/models"),
                path="/v1/models",
            )
            == body
        )
        other_key = CatalogCache(
            root / "catalog", key="other-key", connect=lambda host: offline
        )
        assert other_key.get(host="ai.drwcloud.com", path="/v1/models")[0] == 502
        assert all(
            b"first-key" not in file.read_bytes()
            for file in root.joinpath("catalog").glob("*.json")
        )


def test_catalog_cache_refreshes_successes_and_bounds_storage():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        upstream = Mock(spec=http.client.HTTPConnection)
        upstream.getresponse.side_effect = [
            Mock(status=200, read=Mock(return_value=body))
            for body in (
                b'{"data":[{"id":"old"}]}',
                b'{"data":[{"id":"new"}]}',
                b"{}",
                b"{}",
            )
        ]
        cache = CatalogCache(root / "catalog", key="key", connect=lambda host: upstream)
        assert cache.get(host="ai.drwcloud.com", path="/v1/models")[0] == 200
        assert cache.fetch(host="ai.drwcloud.com", path="/v1/models")[0] == 200
        assert (
            cache.read(
                cache.path(host="ai.drwcloud.com", path="/v1/models"), path="/v1/models"
            )
            == b'{"data":[{"id":"new"}]}'
        )
        with patch("catalog.MAX_CATALOG_FILES", 2):
            for provider in ("openai", "anthropic"):
                assert cache.fetch(
                    host="configs.portkey.ai", path=f"/pricing/{provider}.json"
                ) == (200, b"{}")
        assert len(list(root.joinpath("catalog").glob("*.json"))) == 2
        assert (
            cache.read(
                cache.path(host="ai.drwcloud.com", path="/v1/models"), path="/v1/models"
            )
            is None
        )


def test_catalog_cache_refuses_invalid_data_and_unsafe_cache_files():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        upstream = Mock(spec=http.client.HTTPConnection)
        invalid_bodies = (b"not json", b"{}", b'{"data":{}}')
        upstream.getresponse.side_effect = [
            *[
                Mock(status=200, read=Mock(return_value=body))
                for body in invalid_bodies
            ],
            Mock(status=401, read=Mock(return_value=b'{"data":[]}')),
        ]
        cache = CatalogCache(root / "catalog", key="key", connect=lambda host: upstream)
        file = cache.path(host="ai.drwcloud.com", path="/v1/models")
        for _ in invalid_bodies:
            assert cache.fetch(host="ai.drwcloud.com", path="/v1/models")[0] == 502
            assert not file.exists()
        assert cache.fetch(host="ai.drwcloud.com", path="/v1/models")[0] == 401
        assert not file.exists()
        outside = root / "outside"
        outside.write_bytes(b'{"data":[]}')
        file.symlink_to(outside)
        assert cache.read(file, path="/v1/models") is None
        file.unlink()
        os.mkfifo(file)
        assert cache.read(file, path="/v1/models") is None
        file.unlink()
        file.write_bytes(b'{"data":[]}')
        file.chmod(0o644)
        assert cache.read(file, path="/v1/models") is None
        file.chmod(0o600)
        with patch("catalog.MAX_CATALOG_BYTES", 4):
            assert cache.read(file, path="/v1/models") is None
        with pytest.raises(RuntimeError, match="private and owned"):
            (root / "alias").symlink_to(root / "catalog", target_is_directory=True)
            CatalogCache(root / "alias", key="key", connect=lambda host: upstream)
