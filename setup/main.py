import argparse
import subprocess
from pathlib import Path

from pydantic import BaseModel, Field
from rich.console import Console

from domain.config import load_packages, load_symlinks
from domain.distro import Distro, detect_distro
from result import Err, Ok
from steps.dependencies import install_package
from steps.symlink import is_symlink_correct, perform_symlink

ROOT_DIR = Path(__file__).resolve().parent.parent


class Arguments(BaseModel):
    do_symlink: bool = Field(alias="symlink")
    do_packages: bool = Field(alias="packages")
    do_check: bool = Field(alias="check")
    quiet: bool = False
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


def run_check(
    distro: Distro,
    packages_file: Path | None,
    symlinks_file: Path | None,
    *,
    quiet: bool = False,
) -> int:
    """Read-only: report which packages and symlinks are present, without
    installing or linking anything.

    Returns the number of things missing, for use as an exit code.
    """
    packages = load_packages([packages_file or ROOT_DIR / "packages.json"])
    symlinks = load_symlinks([symlinks_file or ROOT_DIR / "symlinks.json"])
    missing_packages: list[str] = []
    missing_symlinks: list[str] = []
    unchecked: list[str] = []

    if not quiet:
        console.print(f"[bold]Doctor ({distro})[/bold]")
        console.print("[bold]Packages[/bold]")
    for package_id, package in packages.items():
        if package.install.get(distro) is None:
            continue
        if package.check is None:
            if not quiet:
                console.print(f"  [dim]? {package_id} (no check defined)[/dim]")
            unchecked.append(package_id)
            continue

        result = subprocess.run(
            package.check, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        if result.returncode == 0:
            if not quiet:
                console.print(f"  [green]✓[/green] {package_id}")
        else:
            if not quiet:
                console.print(f"  [red]✗[/red] {package_id}")
            missing_packages.append(package_id)

    if not quiet:
        console.print("[bold]Symlinks[/bold]")
    for symlink in symlinks:
        if symlink.distros is not None and distro not in symlink.distros:
            continue

        label = f"{symlink.src} -> {symlink.dst}"
        if is_symlink_correct(symlink):
            if not quiet:
                console.print(f"  [green]✓[/green] {label}")
        else:
            if not quiet:
                console.print(f"  [red]✗[/red] {label}")
            missing_symlinks.append(label)

    total_missing = len(missing_packages) + len(missing_symlinks)
    if total_missing:
        if quiet:
            console.print("[bold red]WARNING: environment is inconsistent with setup configuration defined in dotfiles[/bold red]")
        else:
            console.print(f"\n[bold red]Missing ({total_missing}):[/bold red]")
        for package_id in missing_packages:
            install_cmd = packages[package_id].install.get(distro)
            console.print(f"  {package_id}: {install_cmd}")
        for label in missing_symlinks:
            console.print(f"  symlink: {label}")
        if not quiet:
            console.print(
                f"\n[red]{total_missing} missing[/red] — run with --packages/--symlink to fix, "
                "or run the command above directly"
            )
    elif not quiet:
        console.print("\n[green]Everything checked is in place[/green]")
    if unchecked and not quiet:
        console.print(f"[yellow]{len(unchecked)} package(s) have no check command and were skipped[/yellow]")

    return total_missing


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


def main(args: Arguments) -> int:
    distro_result = detect_distro(override=args.distro)
    match distro_result:
        case Ok(distro):
            pass
        case Err(error):
            console.print(f"[red]✗ Failed to detect distro: {error}[/red]")
            return 1

    if args.do_packages:
        run_packages(distro, args.file)

    missing_count = 0
    if args.do_check:
        missing_count = run_check(distro, args.file, args.file, quiet=args.quiet)

    if args.do_symlink:
        run_symlinks(distro, args.file)

    return 1 if missing_count else 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Dotconfig",
        description="A dependency manager for Oscar's dotfiles",
    )
    parser.add_argument("-s", "--symlink", action="store_true", default=False)
    parser.add_argument("-p", "--packages", action="store_true", default=False)
    parser.add_argument(
        "-c", "--check", action="store_true", default=False,
        help="Report which packages are present without installing anything",
    )
    parser.add_argument(
        "-q", "--quiet", action="store_true", default=False,
        help="With --check: print nothing when everything is present, a one-line warning otherwise",
    )
    parser.add_argument("--distro", choices=[d.value for d in Distro], default=None)
    parser.add_argument(
        "--file",
        default=None,
        help="Use this packages.json/symlinks.json instead of the repo root's, e.g. --file ~/anvil/symlinks.json",
    )
    args = Arguments.model_validate(vars(parser.parse_args()))
    raise SystemExit(main(args))
