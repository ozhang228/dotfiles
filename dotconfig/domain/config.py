import tomllib
from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path

from pydantic import BaseModel
from typing_extensions import Sequence

from domain.distro import Distro
from result import Err, Ok, Result
from steps.dependencies import Dependency
from steps.env_var import EnvVar
from steps.symlink import Symlink


class Metadata(BaseModel):
    name: str
    supported_distros: Sequence[Distro]


class DotConfig(BaseModel):
    metadata: Metadata
    deps: Sequence[Dependency] = []
    symlinks: Sequence[Symlink] = []
    env_vars: Sequence[EnvVar] = []


class AbstractConfig(ABC):
    @abstractmethod
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
