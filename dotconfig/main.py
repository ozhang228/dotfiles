from domain.config import FileConfigs
from domain.distro import detect_distro


def main():
    distro = detect_distro()
    configs = FileConfigs()

    # symlinks, env vars, packages, all locked behind a cmd line flag, and the make
    # then do gh auth login

    print(configs.get_config())


if __name__ == "__main__":
    main()
