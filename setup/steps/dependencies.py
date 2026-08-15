import subprocess
from typing import Literal

from domain.config import Package
from result import Err, Ok, Result

InstallCommand = str
CheckCommand = str
InstallStatus = Literal["installed", "already_present"]


def _already_installed(check_cmd: CheckCommand) -> bool:
    result = subprocess.run(
        check_cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    return result.returncode == 0


def install_package(package: Package, install_cmd: InstallCommand) -> Result[InstallStatus, str]:
    if package.check and _already_installed(package.check):
        return Ok("already_present")

    result = subprocess.run(install_cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or f"exited {result.returncode}").strip()
        return Err(detail)
    return Ok("installed")
