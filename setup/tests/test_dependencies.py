from domain.config import Package
from domain.distro import Distro
from result import Err, Ok
from steps.dependencies import install_package


def test_install_package_reports_already_present_without_running_install_cmd() -> None:
    package = Package(check="true", install={Distro.MANJARO: "exit 1"})

    result = install_package(package, package.install[Distro.MANJARO])

    assert result == Ok("already_present")


def test_install_package_reports_installed_on_success() -> None:
    package = Package(check="false", install={Distro.MANJARO: "true"})

    result = install_package(package, package.install[Distro.MANJARO])

    assert result == Ok("installed")


def test_install_package_captures_stderr_on_failure() -> None:
    package = Package(check="false", install={Distro.MANJARO: "echo 'boom' >&2; exit 1"})

    result = install_package(package, package.install[Distro.MANJARO])

    assert result == Err("boom")
