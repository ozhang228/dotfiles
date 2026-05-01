#!/usr/bin/env python3
"""
Vendor-neutral rules injector.

Usage:
  inject_rules.py --file <path>
  inject_rules.py --bash <command>

Prints all matching rule markdown to stdout, stacked with separators.
Silent (no output, exit 0) if nothing matches.
"""
from __future__ import annotations

import argparse
import shlex
import sys
from pathlib import Path

AI_DIR = Path(__file__).resolve().parent.parent
LANGUAGES_DIR = AI_DIR / "languages"
TASKS_DIR = AI_DIR / "tasks"

EXTENSION_TO_FILE: dict[str, Path] = {
    ".py": LANGUAGES_DIR / "python.md",
    ".ts": LANGUAGES_DIR / "typescript.md",
    ".tsx": LANGUAGES_DIR / "typescript.md",
    ".cpp": LANGUAGES_DIR / "cpp.md",
    ".cc": LANGUAGES_DIR / "cpp.md",
    ".cxx": LANGUAGES_DIR / "cpp.md",
    ".h": LANGUAGES_DIR / "cpp.md",
    ".hpp": LANGUAGES_DIR / "cpp.md",
    ".hxx": LANGUAGES_DIR / "cpp.md",
}

TEST_NAME_SUBSTRINGS: tuple[str, ...] = ("test", "spec")

CLI_TRIGGERS: frozenset[str] = frozenset({"jq", "mlr"})


def _is_test_file(path: Path) -> bool:
    name_lower = path.name.lower()
    return any(frag in name_lower for frag in TEST_NAME_SUBSTRINGS)


def _emit(rules_path: Path, *, for_target: str, kind: str) -> str:
    header = f"# {kind} rules (applies to {for_target})\n\n"
    return header + rules_path.read_text()


def handle_file(path_arg: str) -> str:
    path = Path(path_arg)
    chunks: list[str] = []

    lang_rules = EXTENSION_TO_FILE.get(path.suffix)
    if lang_rules is not None and lang_rules.exists():
        chunks.append(_emit(lang_rules, for_target=path.name, kind=f"{path.suffix} language"))

    if _is_test_file(path):
        testing_rules = TASKS_DIR / "testing.md"
        if testing_rules.exists():
            chunks.append(_emit(testing_rules, for_target=path.name, kind="Testing"))

    return "\n\n---\n\n".join(chunks)


def handle_bash(command: str) -> str:
    try:
        tokens = shlex.split(command)
    except ValueError:
        tokens = command.split()

    if not any(t in CLI_TRIGGERS for t in tokens):
        return ""

    cli_rules = TASKS_DIR / "cli.md"
    if not cli_rules.exists():
        return ""

    return _emit(cli_rules, for_target="this Bash command", kind="CLI tool")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--file")
    group.add_argument("--bash")
    args = parser.parse_args(argv[1:])

    output = handle_file(args.file) if args.file is not None else handle_bash(args.bash)
    if output:
        sys.stdout.write(output)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
