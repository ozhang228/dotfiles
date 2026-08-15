import argparse
from pathlib import Path

from pydantic import BaseModel, Field
from rich.console import Console

from domain.config import load_packages, load_symlinks
from domain.distro import Distro, detect_distro
from result import Err, Ok
from steps.dependencies import install_package
from steps.symlink import perform_symlink

ROOT_DIR = Path(__file__).resolve().parent.parent


class Arguments(BaseModel):
    do_symlink: bool = Field(alias="symlink")
    do_packages: bool = Field(alias="packages")
    distro: Distro | None = None
    file: Path | None = None


console = Console()


def run_packages(distro: Distro, file: Path | None) -> None:
    packages = load_packages([file or ROOT_DIR / "packages.json"])
    failures: list[tuple[str, str]] = []

    console.print(f"[bold]Packages ({distro})[/bold]")
    for package_id, package in packages.items():
        install_cmd = package.install.get(distro)
        if install_cmd is None:
            console.print(f"  [dim]- {package_id} (not available on {distro})[/dim]")
            continue

        result = install_package(package, install_cmd)
        match result:
            case Ok("already_present"):
                console.print(f"  [dim]· {package_id}[/dim]")
            case Ok(_):
                console.print(f"  [green]✓[/green] {package_id}")
            case Err(error):
                console.print(f"  [red]✗[/red] {package_id}")
                failures.append((package_id, error))

    if failures:
        console.print("\n[bold red]Failed:[/bold red]")
        for package_id, error in failures:
            console.print(f"  {package_id}: {error}")
        console.print(f"\n[red]{len(failures)} failed[/red]")
    else:
        console.print("\n[green]All packages installed[/green]")


def run_symlinks(distro: Distro, file: Path | None) -> None:
    symlinks = load_symlinks([file or ROOT_DIR / "symlinks.json"])
    failures: list[tuple[str, str]] = []

    console.print("[bold]Symlinks[/bold]")
    for symlink in symlinks:
        if symlink.distros is not None and distro not in symlink.distros:
            continue

        result = perform_symlink(symlink)
        match result:
            case Ok():
                console.print(f"  [green]✓[/green] {symlink.src} -> {symlink.dst}")
            case Err(error):
                console.print(f"  [red]✗[/red] {symlink.src} -> {symlink.dst}")
                failures.append((f"{symlink.src} -> {symlink.dst}", error))

    if failures:
        console.print("\n[bold red]Failed:[/bold red]")
        for name, error in failures:
            console.print(f"  {name}: {error}")


def main(args: Arguments) -> None:
    distro_result = detect_distro(override=args.distro)
    match distro_result:
        case Ok(distro):
            pass
        case Err(error):
            console.print(f"[red]✗ Failed to detect distro: {error}[/red]")
            return

    if args.do_packages:
        run_packages(distro, args.file)

    if args.do_symlink:
        run_symlinks(distro, args.file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Dotconfig",
        description="A dependency manager for Oscar's dotfiles",
    )
    parser.add_argument("-s", "--symlink", action="store_true", default=False)
    parser.add_argument("-p", "--packages", action="store_true", default=False)
    parser.add_argument("--distro", choices=[d.value for d in Distro], default=None)
    parser.add_argument(
        "--file",
        default=None,
        help="Use this packages.json/symlinks.json instead of the repo root's, e.g. --file ~/anvil/symlinks.json",
    )
    args = Arguments.model_validate(vars(parser.parse_args()))
    main(args)
