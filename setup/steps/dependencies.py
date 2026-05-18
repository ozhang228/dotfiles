import subprocess

from pydantic import BaseModel

from domain.distro import Distro
from result import Err, Ok, Result

InstallCommand = str
CheckCommand = str


class Dependency(BaseModel):
    id: str
    install_method: dict[Distro, InstallCommand]
    check: CheckCommand | None = None


def _already_installed(check_cmd: CheckCommand) -> bool:
    result = subprocess.run(
        check_cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    return result.returncode == 0


def install_dependency(
    dep: Dependency, install_cmd: InstallCommand
) -> Result[str, str]:
    if dep.check and _already_installed(dep.check):
        return Ok(f"{dep.id} already installed, skipping")
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
