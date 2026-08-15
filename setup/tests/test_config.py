import json
from pathlib import Path

from domain.config import load_packages, load_symlinks


def _write_json(path: Path, data: object) -> None:
    path.write_text(json.dumps(data))


def test_packages_load_preserves_declaration_order(tmp_path: Path) -> None:
    packages_path = tmp_path / "packages.json"
    _write_json(
        packages_path,
        {
            "yay": {"check": "command -v yay", "install": {"manjaro": "sh yay.sh"}},
            "node_js": {"check": "command -v node", "install": {"manjaro": "nvm install --lts"}},
            "lazygit": {"check": "command -v lazygit", "install": {"manjaro": "sudo pacman -S lazygit"}},
        },
    )

    packages = load_packages([packages_path])

    assert list(packages.keys()) == ["yay", "node_js", "lazygit"]


def test_anvil_packages_merge_when_present(tmp_path: Path) -> None:
    dotfiles_path = tmp_path / "packages.json"
    _write_json(dotfiles_path, {"lazygit": {"check": "command -v lazygit", "install": {"manjaro": "sudo pacman -S lazygit"}}})

    anvil_path = tmp_path / "anvil_packages.json"
    _write_json(anvil_path, {"drw-internal-cli": {"check": "command -v drw-cli", "install": {"manjaro": "sh drw-cli.sh"}}})

    merged = load_packages([dotfiles_path, anvil_path])

    assert set(merged.keys()) == {"lazygit", "drw-internal-cli"}


def test_anvil_packages_absent_leaves_dotfiles_only(tmp_path: Path) -> None:
    dotfiles_path = tmp_path / "packages.json"
    _write_json(dotfiles_path, {"lazygit": {"check": "command -v lazygit", "install": {"manjaro": "sudo pacman -S lazygit"}}})

    missing_anvil_path = tmp_path / "does-not-exist.json"

    merged = load_packages([dotfiles_path, missing_anvil_path])

    assert set(merged.keys()) == {"lazygit"}


def test_symlinks_load_concatenates_sources(tmp_path: Path) -> None:
    dotfiles_path = tmp_path / "symlinks.json"
    _write_json(dotfiles_path, [{"src": "~/dotfiles/a", "dst": "~/.config/a"}])

    anvil_path = tmp_path / "anvil_symlinks.json"
    _write_json(anvil_path, [{"src": "~/anvil/b", "dst": "~/.config/b"}])

    symlinks = load_symlinks([dotfiles_path, anvil_path])

    assert [str(s.dst) for s in symlinks] == ["~/.config/a", "~/.config/b"]


def test_symlink_distros_field_scopes_by_distro(tmp_path: Path) -> None:
    path = tmp_path / "symlinks.json"
    _write_json(
        path,
        [
            {"src": "~/dotfiles/universal", "dst": "~/.config/universal"},
            {"src": "~/dotfiles/mac-only", "dst": "~/.aerospace.toml", "distros": ["mac"]},
        ],
    )

    symlinks = load_symlinks([path])

    assert symlinks[0].distros is None
    assert symlinks[1].distros == ["mac"]
