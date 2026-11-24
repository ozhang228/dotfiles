from domain.distro import Distro, detect_distro
from result import Ok


def test_distro_override_skips_autodetect() -> None:
    result = detect_distro(override=Distro.UBUNTU)

    assert result == Ok(Distro.UBUNTU)
