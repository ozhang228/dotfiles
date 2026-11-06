import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch


def runtime_module():
    spec = importlib.util.spec_from_file_location(
        "runtime", Path(__file__).parents[1] / "runtime.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def executable(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    path.chmod(0o755)
    return path


def package(modules):
    root = modules / "@earendil-works/pi-coding-agent"
    root.mkdir(parents=True)
    (root / "package.json").write_text(
        json.dumps({"name": "@earendil-works/pi-coding-agent"})
    )
    return executable(root / "dist/bundle/cli.js", "#!/usr/bin/env node\n")


def test_discovers_relocated_drw_and_npm_without_executing_wrappers():
    runtime = runtime_module()
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        node = executable(root / "node-runtime/bin/node", "#!/bin/sh\nexit 42\n")
        drw = executable(
            root / "relocated/bin/pi",
            f"#!{node}\nthrow new Error('wrapper must not execute');\n",
        )
        drw_cli = package(root / "relocated/lib/pi/lib/node_modules")
        with patch.dict(
            os.environ, {"PATH": str(drw.parent), "HOME": str(root)}, clear=True
        ):
            assert runtime.find_runtime() == (node, drw_cli)
        npm_cli = package(root / "npm/lib/node_modules")
        npm_bin = root / "npm/bin"
        npm_bin.mkdir()
        (npm_bin / "pi").symlink_to(npm_cli)
        with patch.dict(
            os.environ,
            {"PATH": f"{npm_bin}:{node.parent}", "HOME": str(root)},
            clear=True,
        ):
            assert runtime.find_runtime() == (node, npm_cli)
            assert runtime.module_root(npm_cli) == root / "npm/lib/node_modules"


def test_setup_refuses_missing_npm_without_creating_runtime():
    script = Path(__file__).resolve().parents[5] / "setup/scripts/pi-sandbox.sh"
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        binaries = root / "bin"
        binaries.mkdir()
        for name in ("dirname", "readlink", "uname", "python3"):
            (binaries / name).symlink_to(shutil.which(name))
        result = subprocess.run(
            ["/bin/sh", str(script)],
            env={"HOME": str(root), "PATH": str(binaries)},
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
        assert result.returncode == 1
        assert result.stderr == (
            "Missing dependency: npm. Install it and rerun dotfiles setup.\n"
        )
        assert not (root / ".local/share/pi-sandbox").exists()


def test_discovers_official_release_skips_sandbox_wrapper_and_refuses_missing_install():
    runtime = runtime_module()
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        wrapper_bin = root / "wrapper/bin"
        wrapper_bin.mkdir(parents=True)
        (wrapper_bin / "pi").symlink_to(Path(__file__).parents[1] / "bin/pi")
        agent = root / "custom-agent"
        data = root / "custom-data"
        launcher = executable(agent / "bin/pi", "#!/bin/sh\nexit 42\n")
        install = agent / "install"
        install.mkdir()
        (install / "managed-install.json").write_text(
            json.dumps(
                {
                    "kind": "pi-managed-install",
                    "schemaVersion": 1,
                    "layout": "releases-v1",
                }
            )
        )
        (install / "current-version").write_text("1.5.0\n")
        cli = package(install / "releases/1.5.0/node_modules")
        release_bin = install / "releases/1.5.0/node_modules/.bin"
        release_bin.mkdir()
        (release_bin / "pi").symlink_to(cli)
        node = executable(data / "pi-node/current/bin/node", "#!/bin/sh\nexit 42\n")
        with patch.dict(
            os.environ,
            {
                "PATH": str(wrapper_bin),
                "HOME": str(root),
                "PI_CODING_AGENT_DIR": str(agent),
                "XDG_DATA_HOME": str(data),
            },
            clear=True,
        ):
            assert runtime.find_runtime() == (node, cli)
            (install / "current-version").write_text("../../credentials\n")
            try:
                runtime.find_runtime()
            except RuntimeError as error:
                assert str(error) == "Invalid managed Pi release version"
            else:
                raise AssertionError("Release escaped its install directory")
            launcher.unlink()
            try:
                runtime.find_runtime()
            except RuntimeError as error:
                assert (
                    str(error)
                    == "No underlying Pi installation found; sandbox wrapper will not recurse"
                )
            else:
                raise AssertionError("Wrapper was used as its own underlying Pi")
        helpers = root / "helpers"
        helpers.mkdir()
        (helpers / "python3").symlink_to(sys.executable)
        executable(helpers / "bwrap", "#!/bin/sh\nexit 42\n")
        project = root / "project"
        project.mkdir()
        injection = root / "injection"
        injection.mkdir()
        sentinel = root / "unrestricted-import"
        (injection / "sitecustomize.py").write_text(
            f"from pathlib import Path\nPath({str(sentinel)!r}).touch()\n"
        )
        result = subprocess.run(
            [str(wrapper_bin / "pi"), "--version"],
            cwd=project,
            env={
                "PATH": f"{wrapper_bin}:{helpers}",
                "HOME": str(root),
                "PYTHONPATH": str(injection),
                "PI_CODING_AGENT_DIR": str(agent),
                "XDG_DATA_HOME": str(data),
            },
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
        assert result.returncode == 1
        assert (
            result.stderr
            == "No underlying Pi installation found; sandbox wrapper will not recurse\n"
        )
        assert not sentinel.exists()
