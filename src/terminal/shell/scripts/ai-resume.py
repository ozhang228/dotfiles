# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path
from typing import assert_never


class Agent(StrEnum):
    PI = "pi"
    CLAUDE = "claude"
    CODEX = "codex"


@dataclass(frozen=True)
class ResumeRequest:
    agent: Agent
    fresh: bool
    arguments: tuple[str, ...]


def main():
    request = parse_arguments()
    root = worktree_root()
    command = resume_command(request, root=root)
    try:
        status = subprocess.run(command, cwd=root, check=False).returncode
    except FileNotFoundError:
        print(f"Agent command not found: {request.agent}", file=sys.stderr)
        return 127
    except OSError as error:
        print(f"Cannot launch {request.agent}: {error}", file=sys.stderr)
        return 126
    return status if status >= 0 else 128 - status


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Resume the current worktree's conversation.",
        allow_abbrev=False,
        add_help=False,
    )
    parser.add_argument("--agent", type=Agent, choices=list(Agent), required=True)
    parser.add_argument("--fresh", action="store_true", help="Start a new session")
    options, arguments = parser.parse_known_args()
    return ResumeRequest(
        agent=Agent(options.agent), fresh=options.fresh, arguments=tuple(arguments)
    )


def worktree_root():
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError:
        return Path.cwd()
    return Path(result.stdout.strip()) if result.returncode == 0 else Path.cwd()


def resume_command(request: ResumeRequest, *, root: Path):
    if request.fresh:
        return [request.agent.value, *request.arguments]

    match request.agent:
        case Agent.PI:
            resume_arguments = ["--continue"]
        case Agent.CLAUDE:
            # Claude Code keeps each directory's sessions under its path with every non-alphanumeric character replaced by "-".
            project_name = re.sub(r"[^a-zA-Z0-9]", "-", str(root))
            project_dir = Path.home() / ".claude/projects" / project_name
            resume_arguments = (
                ["--continue"] if any(project_dir.glob("*.jsonl")) else []
            )
        case Agent.CODEX:
            # Resolve the latest session by its recorded cwd so resume is explicitly worktree-scoped.
            session_id = find_latest_codex_session(root)
            resume_arguments = ["resume", session_id] if session_id else []
        case _ as unreachable:
            assert_never(unreachable)

    return [request.agent.value, *resume_arguments, *request.arguments]


def find_latest_codex_session(root: Path) -> str | None:
    latest_session = None
    for path in (Path.home() / ".codex/sessions").rglob("*.jsonl"):
        try:
            with path.open() as session_file:
                metadata = json.loads(session_file.readline())
            if not isinstance(metadata, dict):
                continue
            payload = metadata.get("payload")
            if (
                metadata.get("type") != "session_meta"
                or not isinstance(payload, dict)
                or payload.get("cwd") != str(root)
            ):
                continue
            session_id = payload.get("id")
            if not isinstance(session_id, str) or not session_id:
                continue
            session = (path.stat().st_mtime_ns, session_id)
            if latest_session is None or session[0] > latest_session[0]:
                latest_session = session
        except (OSError, ValueError):
            continue
    return latest_session[1] if latest_session else None


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
