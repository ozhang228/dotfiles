import subprocess

from pydantic import BaseModel

from domain.distro import Distro
from result import Err, Ok, Result

InstallCommand = str


class Dependency(BaseModel):
    id: str
    install_method: dict[Distro, InstallCommand]


def install_dependency(install_cmd: InstallCommand) -> Result[str, str]:
    try:
        result = subprocess.run(
            install_cmd,
            shell=True,
            text=True,
            check=True,
        )
        return Ok(result.stdout)
    except subprocess.CalledProcessError as e:
        return Err(f"Installation failed: {e.stderr}")
    except Exception as e:
        return Err(f"Error: {e}")
