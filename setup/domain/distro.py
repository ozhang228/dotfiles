import platform
from enum import StrEnum

from result import Err, Ok, Result


class Distro(StrEnum):
    MANJARO = "manjaro"
    UBUNTU = "ubuntu"
    MAC = "mac"


def detect_distro() -> Result[Distro, str]:
    if platform.system() == "Darwin":
        return Ok(Distro.MAC)
    elif platform.system() == "Linux":
        try:
            os_info = platform.freedesktop_os_release()
        except Exception as e:
            return Err(f"Error running platform.freedesktop_os_release {e}")
        distro_id = os_info.get("ID", "").lower()

        if "ubuntu" in distro_id:
            return Ok(Distro.UBUNTU)
        elif "manjaro" in distro_id:
            return Ok(Distro.MANJARO)
        else:
            return Err(f"Unsupported distribution: {distro_id}")

    return Err(f"Unsupported Platform: {platform.system()}")
