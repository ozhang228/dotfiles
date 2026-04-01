import argparse
import os

from pydantic import BaseModel, Field
from rich.console import Console
from rich.panel import Panel

from domain.config import FileConfigs
from domain.distro import detect_distro
from result import Err, Ok
from steps.dependencies import install_dependency
from steps.env_var import RequiredEnvVar
from steps.symlink import perform_symlink


class Arguments(BaseModel):
    do_symlink: bool = Field(alias="symlink")
    do_env_vars: bool = Field(alias="env_vars")
    do_packages: bool = Field(alias="packages")


console = Console()


def main(args: Arguments):
    distro_result = detect_distro()
    match distro_result:
        case Ok(value):
            distro = value
        case Err(error):
            console.print(f"[red]✗ Failed to detect distro: {error}[/red]")
            return

    configs = FileConfigs()

    for config_result in configs.get_config():
        if isinstance(config_result, Err):
            console.print(f"[red]✗ Failed to get config: {config_result.error}[/red]")
            continue

        config = config_result.value
        console.print(Panel(renderable=f"{config.metadata.name}", style="magenta"))

        if distro not in config.metadata.supported_distros:
            console.print("[red]✗ Distro is unsupported")
            continue

        if args.do_symlink:
            console.print("[blue]--- Symlinks ---")
            for sym in config.symlinks:
                console.rule(f"[bold cyan]{sym.src} -> {sym.dst}[/bold cyan]")
                symlink_result = perform_symlink(sym)
                match symlink_result:
                    case Ok():
                        console.print(
                            f"[green]✓[/green] Symlinked {sym.src} -> {sym.dst}"
                        )
                    case Err(error):
                        console.print(f"[red]✗[/red] Symlink failed: {error}")

        if args.do_env_vars:
            console.print("[blue]--- Env Vars ---")
            for env_var in config.env_vars:
                console.rule(f"[bold cyan]{env_var}[/bold cyan]")
                os_var = os.getenv(env_var.key)
                match env_var:
                    case RequiredEnvVar():
                        if os_var is None:
                            console.print(
                                f"[yellow]⚠[/yellow] {env_var.key} is not set"
                            )
                        else:
                            console.print(
                                f"[green]✓[/green] {env_var.key} = '{os_var}'"
                            )

        if args.do_packages:
            console.print("[blue]--- Packages ---")

            installed_packages = set[str]()
            for dep in config.deps:
                if dep.id in installed_packages:
                    console.print(
                        f"[yellow]⚠[/yellow] {dep.id} already installed. Skipping"
                    )
                installed_packages.add(dep.id)

                install_cmd = dep.install_method.get(distro)
                if install_cmd is None:
                    console.print(f"[yellow]⚠[/yellow] No command for {distro}")
                    continue

                console.rule(f"[bold cyan]{dep.id}[/bold cyan]")
                console.print(f"[dim]$ {install_cmd}[/dim]\n")

                installation_result = install_dependency(install_cmd)
                match installation_result:
                    case Ok(success):
                        console.print(f"[green]✓[/green] {success}")
                    case Err(error):
                        console.print(f"[red]✗[/red] Failed to install: {error}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Dotconfig",
        description="A dependency manager for Oscar's dotfiles",
    )
    parser.add_argument("-s", "--symlink", action="store_true", default=False)
    parser.add_argument("-e", "--env_vars", action="store_true", default=False)
    parser.add_argument("-p", "--packages", action="store_true", default=False)
    args = Arguments.model_validate(vars(parser.parse_args()))
    main(args)
