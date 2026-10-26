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

    print("  Installing...", flush=True)
    result = subprocess.run(install_cmd, shell=True)
    if result.returncode != 0:
        return Err(f"Installer exited with status {result.returncode}; see output above")
    return Ok("installed")
