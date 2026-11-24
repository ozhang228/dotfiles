from pathlib import Path

from domain.config import load_packages, load_symlinks

REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def test_real_packages_json_parses_and_leads_with_yay_and_node() -> None:
    packages = load_packages([REPO_ROOT / "packages.json"])

    ids = list(packages.keys())
    assert ids[0] == "yay"
    assert ids[1] == "node_version_manager"
    assert ids[2] == "node_js"
    assert len(set(ids)) == len(ids)


def test_real_symlinks_json_parses() -> None:
    symlinks = load_symlinks([REPO_ROOT / "symlinks.json"])

    assert len(symlinks) > 0
    mac_only = [s for s in symlinks if s.distros == ["mac"]]
    assert any(str(s.dst) == "~/.aerospace.toml" for s in mac_only)
