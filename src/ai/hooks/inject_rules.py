#!/usr/bin/env python3
"""
Vendor-neutral rules injector.

Usage:
  inject_rules.py --file <path>       # single file (legacy / direct call)
  inject_rules.py --bash <command>    # bash command
  inject_rules.py --prompt <text>     # full user prompt text (UserPromptSubmit)

Prints all matching rule markdown to stdout, stacked with separators.
Silent (no output, exit 0) if nothing matches.
"""

from __future__ import annotations

import argparse
import re
import shlex
import sys
from pathlib import Path

AI_DIR = Path(__file__).resolve().parent.parent
RULES_DIR = AI_DIR / "rules"

EXTENSION_TO_FILE: dict[str, Path] = {
    ".py": RULES_DIR / "python.md",
    ".ts": RULES_DIR / "typescript.md",
    ".tsx": RULES_DIR / "typescript.md",
    ".cpp": RULES_DIR / "cpp.md",
    ".cc": RULES_DIR / "cpp.md",
    ".cxx": RULES_DIR / "cpp.md",
    ".h": RULES_DIR / "cpp.md",
    ".hpp": RULES_DIR / "cpp.md",
    ".hxx": RULES_DIR / "cpp.md",
}

TEST_NAME_SUBSTRINGS: tuple[str, ...] = ("test", "spec")

CLI_TRIGGERS: frozenset[str] = frozenset({"jq", "mlr"})


def _is_test_file(path: Path) -> bool:
    name_lower = path.name.lower()
    return any(frag in name_lower for frag in TEST_NAME_SUBSTRINGS)


def _emit(rules_path: Path, *, for_target: str, kind: str) -> str:
    header = f"# {kind} rules (applies to {for_target})\n\n"
    return header + rules_path.read_text()


def _emit_skill_directive(
    skill_name: str, *, for_target: str, condition: str = ""
) -> str:
    header = f"# Skill directive (applies to {for_target})\n\n"
    cond = f" {condition}" if condition else ""
    return (
        header + f"You MUST invoke the `{skill_name}` skill via the Skill tool{cond}."
    )


def handle_file(path_arg: str) -> str:
    path = Path(path_arg)
    chunks: list[str] = []

    lang_rules = EXTENSION_TO_FILE.get(path.suffix)
    if lang_rules is not None and lang_rules.exists():
        chunks.append(
            _emit(lang_rules, for_target=path.name, kind=f"{path.suffix} language")
        )

    if path.suffix == ".py":
        chunks.append(
            _emit_skill_directive(
                "python-review",
                for_target=path.name,
                condition="if this session involves reviewing Python code (PR review, code review)",
            )
        )

    if _is_test_file(path):
        chunks.append(
            _emit_skill_directive(
                "testing",
                for_target=path.name,
                condition="before writing or modifying any tests",
            )
        )

    return "\n\n---\n\n".join(chunks)


def handle_bash(command: str) -> str:
    try:
        tokens = shlex.split(command)
    except ValueError:
        tokens = command.split()

    if not any(t in CLI_TRIGGERS for t in tokens):
        return ""

    cli_rules = RULES_DIR / "cli.md"
    if not cli_rules.exists():
        return ""

    return _emit(cli_rules, for_target="this Bash command", kind="CLI tool")


def handle_prompt(prompt: str) -> str:
    """Scan the user's message for file extensions and CLI tool mentions."""
    chunks: list[str] = []
    seen_exts: set[str] = set()
    has_test_file = False

    # Extract file paths from @mentions and bare paths in the prompt
    for match in re.finditer(r"[@\s\"']?([\w./\-]+\.\w+)", prompt):
        path = Path(match.group(1))
        ext = path.suffix.lower()
        if ext in EXTENSION_TO_FILE and ext not in seen_exts:
            seen_exts.add(ext)
            rules = EXTENSION_TO_FILE[ext]
            if rules.exists():
                chunks.append(_emit(rules, for_target=ext + " files", kind=f"{ext} language"))
        if _is_test_file(path):
            has_test_file = True

    if ".py" in seen_exts:
        chunks.append(
            _emit_skill_directive(
                "python-review",
                for_target=".py files",
                condition="if this session involves reviewing Python code (PR review, code review)",
            )
        )

    if has_test_file:
        chunks.append(
            _emit_skill_directive(
                "testing",
                for_target="test files",
                condition="before writing or modifying any tests",
            )
        )

    # CLI tool mentions in the prompt
    try:
        tokens = shlex.split(prompt)
    except ValueError:
        tokens = prompt.split()
    if any(t in CLI_TRIGGERS for t in tokens):
        cli_rules = RULES_DIR / "cli.md"
        if cli_rules.exists():
            chunks.append(_emit(cli_rules, for_target="this session", kind="CLI tool"))

    return "\n\n---\n\n".join(chunks)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--file")
    group.add_argument("--bash")
    group.add_argument("--prompt")
    args = parser.parse_args(argv[1:])

    if args.file is not None:
        output = handle_file(args.file)
    elif args.bash is not None:
        output = handle_bash(args.bash)
    else:
        output = handle_prompt(args.prompt)

    if output:
        sys.stdout.write(output)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
