from pathlib import Path

from pydantic import BaseModel
from typing_extensions import Literal, Sequence

from domain.distro import Distro

InstallCommand = str


class Depencency(BaseModel):
    name: str
    description: str
    install_method: dict[Distro, InstallCommand]


class Symlink(BaseModel):
    src: Path
    dst: Path


class RequiredEnvVar(BaseModel):
    type: Literal["required"] = "required"


class SetEnvVar(BaseModel):
    type: Literal["set"] = "set"
    value: str


class DotConfig(BaseModel):
    deps: Sequence[Depencency]
    symlinks: Sequence[Symlink]
    env_vars: Sequence[RequiredEnvVar | SetEnvVar]
