import tomllib
from abc import ABC
from dataclasses import dataclass
from pathlib import Path

from pydantic import BaseModel
from typing_extensions import Literal, Sequence

from domain.distro import Distro
from result import Err, Ok, Result

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
    deps: Sequence[Depencency] = []
    symlinks: Sequence[Symlink] = []
    env_vars: Sequence[RequiredEnvVar | SetEnvVar] = []


class AbstractConfig(ABC):
    def get_config(self) -> Sequence[Result[DotConfig, str]]: ...


@dataclass
class StubConfig(AbstractConfig):
    config: Sequence[Result[DotConfig, str]]

    def get_config(self) -> Sequence[Result[DotConfig, str]]:
        return self.config


class FileConfigs(AbstractConfig):
    def __init__(self):
        dotfiles = Path.home() / "dotfiles"
        config_paths = list(dotfiles.rglob("dotconfig.toml"))

        self.configs = list[Result[DotConfig, str]]()
        for path in config_paths:
            try:
                with path.open("rb") as f:
                    parsed_toml = DotConfig.model_validate(tomllib.load(f))
                    self.configs.append(Ok(parsed_toml))
            except Exception as e:
                self.configs.append(Err(f"Failed to get config file for {path}: {e}"))

    def get_config(self) -> Sequence[Result[DotConfig, str]]:
        return self.configs
