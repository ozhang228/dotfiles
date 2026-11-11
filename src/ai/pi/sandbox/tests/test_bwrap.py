import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest


@pytest.mark.parametrize("profile", [False, True])
def test_native_json_mask_is_readable_but_cannot_be_changed(profile):
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        repo = root / "repo"
        repo.mkdir()
        placeholder = repo / ".mcp.json"
        placeholder.touch()
        (repo / "nested").mkdir()
        existing = repo / "nested/.mcp.json"
        existing.write_text('{"keep": true}')
        empty = root / "empty-mask"
        empty.touch(mode=0o400)
        mounts = [
            "--unshare-user",
            "--unshare-pid",
            "--unshare-net",
            "--die-with-parent",
            "--ro-bind",
            "/",
            "/",
            "--dev",
            "/dev",
            "--proc",
            "/proc",
            "--bind",
            str(repo),
            str(repo),
            "--ro-bind",
            "/dev/null",
            str(placeholder),
            "--ro-bind",
            str(existing),
            str(existing),
        ]
        source = "\n".join(
            [
                "import os,sys",
                "from pathlib import Path",
                "root=Path(sys.argv[1]); placeholder=root/'.mcp.json'",
                "assert placeholder.is_file() and placeholder.read_bytes()==b''",
                "assert (root/'nested/.mcp.json').read_text()=='{\"keep\": true}'",
                "for operation in (lambda: placeholder.write_text('bad'), lambda: placeholder.unlink(), lambda: placeholder.rename(root/'moved'), lambda: (root/'nested/.mcp.json').write_text('bad')):",
                "    try: operation()",
                "    except OSError: pass",
                "    else: raise AssertionError('protected config was writable')",
                "(root/'new').write_text('allowed write')",
                "print('protected')",
            ]
        )
        with tempfile.TemporaryFile(dir=root) as mount_profile:
            descriptor = mount_profile.fileno()
            if profile:
                os.write(descriptor, b"\0".join(map(os.fsencode, mounts)) + b"\0")
                os.lseek(descriptor, 0, os.SEEK_SET)
                mounts = ["--args", str(descriptor)]
            result = subprocess.run(
                [
                    str(Path(__file__).resolve().parents[1] / "bwrap"),
                    *mounts,
                    "--",
                    sys.executable,
                    "-c",
                    source,
                    str(repo),
                ],
                env={"PI_SANDBOX_EMPTY_MASK": str(empty)},
                pass_fds=(descriptor,),
                capture_output=True,
                text=True,
                check=False,
                timeout=10,
            )
        assert result.returncode == 0, result.stderr
        assert result.stdout == "protected\n"
        assert placeholder.read_bytes() == b""
        assert existing.read_text() == '{"keep": true}'
        assert (repo / "new").read_text() == "allowed write"
