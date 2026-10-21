#!/usr/bin/env python3
import argparse
import fcntl
import hashlib
import os
from pathlib import Path
import re
import select
import signal
import subprocess
import sys
import time


def pane_scope(pid: int):
    try:
        cgroup = Path(f"/proc/{pid}/cgroup").read_text()
    except FileNotFoundError:
        return None
    return next(iter(re.findall(r"(?<=/)tmux-spawn-[0-9a-f-]{36}\.scope\b", cgroup)), None)


def stop_scopes(scopes: set[str]):
    for scope in sorted(scopes):
        # A pane can exit before its session, in which case systemd removes its scope.
        loaded = subprocess.run(
            ["systemctl", "--user", "show", "--property=LoadState", "--value", scope],
            check=True, capture_output=True, text=True,
        ).stdout.strip()
        if loaded == "not-found":
            continue
        print(f"Stopping {scope}", flush=True)
        try:
            subprocess.run(["systemctl", "--user", "stop", scope], check=True, timeout=3)
        except subprocess.TimeoutExpired:
            subprocess.run(
                ["systemctl", "--user", "kill", "--signal=SIGKILL", scope], check=True,
            )
            subprocess.run(["systemctl", "--user", "stop", scope], check=True, timeout=5)


def sync_sessions(*, socket: str, server: int):
    state_root = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    state_root = state_root / "tmux/processes"
    state_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    key = hashlib.sha256(f"{socket}:{server}".encode()).hexdigest()
    state = state_root / key
    with (state_root / f"{key}.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        owners = {}
        if state.exists():
            for line in state.read_text().splitlines():
                scope, *sessions = line.split("\t")
                if not re.fullmatch(r"tmux-spawn-[0-9a-f-]{36}\.scope", scope):
                    raise ValueError(f"Invalid scope in {state}")
                owners[scope] = set(sessions)

        sessions_result = subprocess.run(
            ["tmux", "-S", socket, "list-sessions", "-F", "#{session_id}"],
            capture_output=True, text=True,
        )
        if sessions_result.returncode:
            error = sessions_result.stderr
            if not any(message in error for message in ("no server running", "no sessions", "No such file or directory")):
                raise RuntimeError(error)
            sessions = set()
        else:
            sessions = set(sessions_result.stdout.splitlines())
            panes = subprocess.run(
                ["tmux", "-S", socket, "list-panes", "-a", "-F", "#{session_id} #{pane_pid}"],
                check=True, capture_output=True, text=True,
            ).stdout
            current = {}
            for line in panes.splitlines():
                session, pid = line.split()
                scope = pane_scope(int(pid))
                if scope:
                    current.setdefault(scope, set()).add(session)
            # Live panes may have moved or been linked to another session.
            owners.update(current)

        expired = {scope for scope, members in owners.items() if members.isdisjoint(sessions)}
        stop_scopes(expired)
        temporary = state.with_suffix(".tmp")
        temporary.write_text("".join(
            "\t".join([scope, *sorted(members & sessions)]) + "\n"
            for scope, members in sorted(owners.items()) if scope not in expired
        ))
        temporary.replace(state)


def stop_worktree(path: Path):
    root = path.resolve(strict=True)
    git_root = subprocess.run(
        ["git", "-C", str(root), "rev-parse", "--show-toplevel"],
        check=True, capture_output=True, text=True,
    ).stdout.strip()
    if root == Path.home() or root == Path("/") or root != Path(git_root).resolve():
        raise ValueError(f"Refusing non-worktree path: {root}")

    parents = {}
    selected = set()
    handles = {}
    try:
        for entry in Path("/proc").iterdir():
            if not entry.name.isdecimal():
                continue
            pid = int(entry.name)
            try:
                if entry.stat().st_uid != os.getuid():
                    continue
                handle = os.pidfd_open(pid)
            except (FileNotFoundError, ProcessLookupError):
                continue
            handles[pid] = handle
            try:
                status = (entry / "stat").read_text().rsplit(")", 1)[1].split()
                parents[pid] = int(status[1])
                cwd = os.readlink(entry / "cwd").removesuffix(" (deleted)")
            except (FileNotFoundError, PermissionError, ProcessLookupError):
                continue
            if Path(cwd).is_relative_to(root):
                selected.add(pid)

        protected = set()
        ancestor = os.getpid()
        while ancestor and ancestor not in protected:
            protected.add(ancestor)
            ancestor = parents.get(ancestor, 0)
        selected -= protected
        while True:
            children = {pid for pid, parent in parents.items() if parent in selected} - protected
            if children <= selected:
                break
            selected |= children

        pending = {handles[pid] for pid in selected}
        for signum in (signal.SIGTERM, signal.SIGKILL):
            for handle in pending:
                try:
                    signal.pidfd_send_signal(handle, signum)
                except ProcessLookupError:
                    pass
            # pidfds remain tied to these processes even if a PID is reused.
            deadline = time.monotonic() + 3
            while pending and time.monotonic() < deadline:
                finished, _, _ = select.select(list(pending), [], [], max(0, deadline - time.monotonic()))
                pending -= set(finished)
            if not pending:
                break
        if pending:
            raise RuntimeError(f"{len(pending)} processes did not stop; keeping worktree")
        if selected:
            print(f"Stopped {len(selected)} processes in {root}")
    finally:
        for handle in handles.values():
            os.close(handle)


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    sync = commands.add_parser("sync")
    sync.add_argument("socket")
    sync.add_argument("server", type=int)
    worktree = commands.add_parser("worktree")
    worktree.add_argument("path", type=Path)
    args = parser.parse_args()
    if sys.platform != "linux":
        parser.error("Process cleanup currently requires Linux")
    if args.command == "sync":
        sync_sessions(socket=args.socket, server=args.server)
    else:
        stop_worktree(args.path)


if __name__ == "__main__":
    main()
