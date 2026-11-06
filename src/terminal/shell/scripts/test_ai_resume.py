import importlib.util
import json
import sys
import tempfile
from pathlib import Path
from subprocess import CompletedProcess
from unittest.mock import patch


def load_resume():
    path = Path(__file__).with_name("ai-resume.py")
    spec = importlib.util.spec_from_file_location("ai_resume_test_subject", path)
    if spec is None or spec.loader is None:
        raise RuntimeError("Cannot load ai-resume")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def saved_session(home: Path, *, repo: Path, provider: str):
    (home / "sessions").mkdir(parents=True)
    (home / "config.toml").write_text(
        'model_provider = "portkey"\n[model_providers.portkey]\n'
    )
    (home / "sessions/session.jsonl").write_text(
        json.dumps(
            {
                "type": "session_meta",
                "payload": {
                    "id": "saved-conversation",
                    "cwd": str(repo),
                    "model_provider": provider,
                },
            }
        )
        + "\n"
    )


def test_missing_provider_forks_worktree_history_with_current_provider():
    resume = load_resume()
    with tempfile.TemporaryDirectory() as folder:
        repo = Path(folder) / "repo"
        home = Path(folder) / "custom-codex-home"
        saved_session(home, repo=repo, provider="portkey-mantle")
        request = resume.ResumeRequest(
            resume.Agent.CODEX, fresh=False, arguments=("--no-daemon",)
        )
        with patch.dict("os.environ", {"CODEX_HOME": str(home)}):
            command = resume.resume_command(request, root=repo)
        assert command == [
            "codex",
            "fork",
            "saved-conversation",
            "-c",
            'model_provider="portkey"',
            "--no-daemon",
        ]


def test_failed_resume_starts_fresh_but_success_and_interrupts_do_not_retry():
    resume = load_resume()
    with tempfile.TemporaryDirectory() as folder:
        repo = Path(folder) / "repo"
        home = Path(folder) / "custom-codex-home"
        saved_session(home, repo=repo, provider="portkey")
        for first_status in (1, 0, 130, 143, -2):
            calls = []

            def run(command, **kwargs):
                if command[0] == "git":
                    return CompletedProcess(command, 0, stdout=str(repo))
                assert kwargs == {"cwd": repo, "check": False}
                calls.append(command)
                return CompletedProcess(command, first_status if len(calls) == 1 else 7)

            with (
                patch.dict("os.environ", {"CODEX_HOME": str(home)}),
                patch.object(
                    sys, "argv", ["ai-resume", "--agent", "codex", "--no-daemon"]
                ),
                patch.object(resume.subprocess, "run", side_effect=run),
            ):
                status = resume.main()
            if first_status == 1:
                assert calls == [
                    ["codex", "resume", "saved-conversation", "--no-daemon"],
                    ["codex", "--no-daemon"],
                ]
                assert status == 7
            else:
                assert calls == [
                    ["codex", "resume", "saved-conversation", "--no-daemon"]
                ]
                assert status == (130 if first_status == -2 else first_status)
