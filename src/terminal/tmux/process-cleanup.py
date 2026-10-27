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
    match = re.search(r"(?<=/)tmux-spawn-[0-9a-f-]{36}\.scope\b", cgroup)
    return match.group() if match else None


def stop_scopes(scopes: set[str]):
    for scope in sorted(scopes):
        # A pane can exit before its session, in which case systemd removes its scope.
        loaded = subprocess.check_output(
            ["systemctl", "--user", "show", "--property=LoadState", "--value", scope],
            text=True,
        ).strip()
        if loaded == "not-found":
            continue
        try:
            subprocess.run(
                ["systemctl", "--user", "stop", scope], check=True, timeout=3
            )
        except subprocess.TimeoutExpired:
            subprocess.run(
                ["systemctl", "--user", "kill", "--signal=SIGKILL", scope],
                check=True,
            )
            subprocess.run(
                ["systemctl", "--user", "stop", scope], check=True, timeout=5
            )


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
                scope, *saved_sessions = line.split("\t")
                if not re.fullmatch(r"tmux-spawn-[0-9a-f-]{36}\.scope", scope):
                    raise ValueError(f"Invalid scope in {state}")
                owners[scope] = set(saved_sessions)

        sessions = set()
        sessions_result = subprocess.run(
            ["tmux", "-S", socket, "list-sessions", "-F", "#{pid} #{session_id}"],
            capture_output=True,
            text=True,
        )
        if sessions_result.returncode:
            error = sessions_result.stderr
            if not any(
                message in error
                for message in (
                    "no server running",
                    "no sessions",
                    "No such file or directory",
                )
            ):
                raise RuntimeError(error)
        else:
            for line in sessions_result.stdout.splitlines():
                server_pid, session = line.split()
                if int(server_pid) == server:
                    sessions.add(session)
        if sessions:
            panes = subprocess.check_output(
                [
                    "tmux",
                    "-S",
                    socket,
                    "list-panes",
                    "-a",
                    "-F",
                    "#{pid} #{session_id} #{pane_pid}",
                ],
                text=True,
            )
            current = {}
            for line in panes.splitlines():
                server_pid, session, pid = line.split()
                if int(server_pid) != server:
                    continue
                # A session can be created between the two tmux queries.
                sessions.add(session)
                scope = pane_scope(int(pid))
                if scope is not None:
                    current.setdefault(scope, set()).add(session)
            # Live panes may have moved or been linked to another session.
            owners.update(current)

        expired = {
            scope for scope, members in owners.items() if members.isdisjoint(sessions)
        }
        stop_scopes(expired)
        temporary = state.with_suffix(".tmp")
        with temporary.open("w") as output:
            for scope, members in sorted(owners.items()):
                if scope not in expired:
                    print(scope, *sorted(members & sessions), sep="\t", file=output)
        temporary.replace(state)


def stop_worktree(path: Path):
    root = path.resolve(strict=True)
    git_root = subprocess.check_output(
        ["git", "-C", str(root), "rev-parse", "--show-toplevel"],
        text=True,
    ).strip()
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
            children = {
                pid for pid, parent in parents.items() if parent in selected
            } - protected
            if children <= selected:
                break
            selected |= children

        pending = {handles[pid] for pid in selected}
        poller = select.poll()
        for handle in pending:
            poller.register(handle, select.POLLIN)
        for signum in (signal.SIGTERM, signal.SIGKILL):
            for handle in pending:
                try:
                    signal.pidfd_send_signal(handle, signum)
                except ProcessLookupError:
                    pass
            # pidfds remain tied to these processes even if a PID is reused.
            deadline = time.monotonic() + 3
            while pending:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    break
                for handle, _ in poller.poll(max(1, int(remaining * 1000))):
                    pending.remove(handle)
                    poller.unregister(handle)
            if not pending:
                break
        if pending:
            raise RuntimeError(
                f"{len(pending)} processes did not stop; keeping worktree"
            )
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
