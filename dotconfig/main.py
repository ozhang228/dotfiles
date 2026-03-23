from domain.config import FileConfigs
from domain.distro import detect_distro


def main():
    distro = detect_distro()
    configs = FileConfigs()

    print(configs.get_config())


if __name__ == "__main__":
    main()
