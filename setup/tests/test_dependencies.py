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


def test_install_package_shows_output_and_reports_failure(capfd) -> None:
    package = Package(check="false", install={Distro.MANJARO: "echo 'progress'; echo 'boom' >&2; exit 1"})

    result = install_package(package, package.install[Distro.MANJARO])

    output = capfd.readouterr()
    assert "progress\n" in output.out
    assert output.err == "boom\n"
    assert result == Err("Installer exited with status 1; see output above")
