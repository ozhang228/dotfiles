import json
from pathlib import Path
from typing import Sequence

from pydantic import BaseModel

from domain.distro import Distro


class Package(BaseModel):
    check: str | None = None
    install: dict[Distro, str]


class Symlink(BaseModel):
    src: Path
    dst: Path
    distros: list[Distro] | None = None


def load_packages(paths: Sequence[Path]) -> dict[str, Package]:
    merged: dict[str, Package] = {}
    for path in paths:
        if not path.exists():
            continue
        with path.open() as f:
            data = json.load(f)
        for package_id, entry in data.items():
            merged[package_id] = Package.model_validate(entry)
    return merged


def load_symlinks(paths: Sequence[Path]) -> list[Symlink]:
    merged: list[Symlink] = []
    for path in paths:
        if not path.exists():
            continue
        with path.open() as f:
            data = json.load(f)
        merged.extend(Symlink.model_validate(item) for item in data)
    return merged
