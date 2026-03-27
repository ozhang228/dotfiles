import argparse
import os

from pydantic import BaseModel, Field

from domain.config import FileConfigs
from domain.distro import detect_distro
from result import Err, Ok, expect_never
from steps.env_var import RequiredEnvVar
from steps.symlink import perform_symlink


class Arguments(BaseModel):
    do_symlink: bool = Field(alias="symlink")
    do_env_vars: bool = Field(alias="env_vars")
    do_packages: bool = Field(alias="packages")


def main(args: Arguments):
    distro = detect_distro()
    configs = FileConfigs()

    # packages
    # then do gh auth login
    for config_result in configs.get_config():
        if isinstance(config_result, Err):
            print(f"Failed to get config with err: {config_result.error}")
            continue

        config = config_result.value

        if args.do_symlink:
            print("""
            ----- Symlinks -----\n
            """)

            for sym in config.symlinks:
                symlink_result = perform_symlink(sym)

                match symlink_result:
                    case Ok():
                        print(f"Symlinked {sym.src} -> {sym.dst}")
                    case Err(error):
                        print(f"Symlink failed with err: {error}")

        if args.do_env_vars:
            print("""
            ----- Env Vars -----\n
            """)
            for env_var in config.env_vars:
                os_var = os.getenv(env_var.key)
                match env_var:
                    case RequiredEnvVar():
                        if os_var is None:
                            print(f"{env_var.key} environment variable is not set")
                        else:
                            print(
                                f"{env_var.key} environment variable is set to '{os_var}'"
                            )

                    case _:
                        expect_never(env_var)
        if args.do_packages:
            print("""
            ----- Package Installs -----\n
            """)


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
