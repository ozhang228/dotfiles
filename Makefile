.PHONY: ubuntu manjaro mac symlink anvil-symlink

ubuntu:
	cd setup && uv run python main.py --packages --distro ubuntu

manjaro:
	cd setup && uv run python main.py --packages --distro manjaro

mac:
	cd setup && uv run python main.py --packages --distro mac

symlink:
	cd setup && uv run python main.py --symlink

anvil-symlink:
	cd setup && uv run python main.py --symlink --file ~/anvil/symlinks.json
