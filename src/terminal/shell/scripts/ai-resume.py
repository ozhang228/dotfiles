# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import argparse
import json
import os
import re
import subprocess
import sys
import tomllib
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


@dataclass(frozen=True)
class CodexSession:
    id: str
    provider: str | None


def main():
    request = parse_arguments()
    root = worktree_root()
    command = resume_command(request, root=root)
    try:
        status = subprocess.run(command, cwd=root, check=False).returncode
        if (
            request.agent == Agent.CODEX
            and len(command) > 1
            and command[1] in {"resume", "fork"}
            and status > 0
            and status not in {130, 143}
        ):
            print("Codex resume failed; starting a fresh session.", file=sys.stderr)
            status = subprocess.run(
                ["codex", *request.arguments], cwd=root, check=False
            ).returncode
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
    match request.agent:
        case Agent.PI:
            launcher = Path(__file__).resolve().parents[3] / "ai/pi/sandbox/bin/pi"
            return [
                str(launcher),
                *([] if request.fresh else ["--continue"]),
                *request.arguments,
            ]
        case Agent.CLAUDE:
            if request.fresh:
                return [request.agent.value, *request.arguments]
            # Claude Code keeps each directory's sessions under its path with every non-alphanumeric character replaced by "-".
            project_name = re.sub(r"[^a-zA-Z0-9]", "-", str(root))
            project_dir = Path.home() / ".claude/projects" / project_name
            resume_arguments = (
                ["--continue"] if any(project_dir.glob("*.jsonl")) else []
            )
        case Agent.CODEX:
            if request.fresh:
                return [request.agent.value, *request.arguments]
            # Resolve the latest session by its recorded cwd so resume is explicitly worktree-scoped.
            home = Path(os.environ.get("CODEX_HOME", str(Path.home() / ".codex")))
            session = find_latest_codex_session(root, home=home)
            resume_arguments = []
            if session:
                config_path = home / "config.toml"
                config = (
                    tomllib.loads(config_path.read_text())
                    if config_path.exists()
                    else {}
                )
                providers = {
                    "openai",
                    "ollama",
                    "lmstudio",
                    *config.get("model_providers", {}),
                }
                if session.provider and session.provider not in providers:
                    provider = config.get("model_provider", "openai")
                    print(
                        f"Saved provider {session.provider!r} is unavailable; forking history with {provider!r}.",
                        file=sys.stderr,
                    )
                    resume_arguments = [
                        "fork",
                        session.id,
                        "-c",
                        f"model_provider={json.dumps(provider)}",
                    ]
                else:
                    resume_arguments = ["resume", session.id]
        case _ as unreachable:
            assert_never(unreachable)

    return [request.agent.value, *resume_arguments, *request.arguments]


def find_latest_codex_session(root: Path, *, home: Path) -> CodexSession | None:
    latest_session = None
    for path in (home / "sessions").rglob("*.jsonl"):
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
            provider = payload.get("model_provider")
            if provider is not None and not isinstance(provider, str):
                continue
            session = (path.stat().st_mtime_ns, CodexSession(session_id, provider))
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
