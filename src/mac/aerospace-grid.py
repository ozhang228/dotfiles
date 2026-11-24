# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import json
import os
import subprocess
import sys
from math import isqrt
from typing import NewType

WindowId = NewType("WindowId", int)
WorkspaceName = NewType("WorkspaceName", str)


def aerospace(*arguments: str, workspace: WorkspaceName | None = None):
    environment = {
        key: value
        for key, value in os.environ.items()
        if key not in {"AEROSPACE_WINDOW_ID", "AEROSPACE_WORKSPACE"}
    }
    if workspace is not None:
        environment["AEROSPACE_WORKSPACE"] = workspace
    return subprocess.run(
        ["aerospace", *arguments],
        check=True,
        capture_output=True,
        text=True,
        env=environment,
    ).stdout


def focused_workspace():
    records = json.loads(
        aerospace("list-workspaces", "--focused", "--json", "--format", "%{workspace}")
    )
    if (
        not isinstance(records, list)
        or len(records) != 1
        or not isinstance(records[0], dict)
        or not isinstance(records[0].get("workspace"), str)
        or not records[0]["workspace"]
    ):
        raise ValueError("AeroSpace did not report one focused workspace")
    return WorkspaceName(records[0]["workspace"])


def window_ids(*filters: str, tiled_only: bool = False):
    records = json.loads(
        aerospace(
            "list-windows",
            *filters,
            "--json",
            "--format",
            "%{window-id} %{window-parent-container-layout}",
        )
    )
    if not isinstance(records, list):
        raise ValueError("AeroSpace did not report a window list")
    result = []
    for record in records:
        if (
            not isinstance(record, dict)
            or type(record.get("window-id")) is not int
            or record["window-id"] <= 0
            or not isinstance(record.get("window-parent-container-layout"), str)
        ):
            raise ValueError("AeroSpace reported an invalid window")
        if not tiled_only or record["window-parent-container-layout"] in {
            "h_tiles",
            "v_tiles",
            "h_accordion",
            "v_accordion",
        }:
            result.append(WindowId(record["window-id"]))
    if len(set(result)) != len(result):
        raise ValueError("AeroSpace reported duplicate window IDs")
    return tuple(result)


def arrange_grid():
    workspace = focused_workspace()
    count = len(window_ids("--workspace", workspace, tiled_only=True))
    if count == 0:
        return
    focused = window_ids("--focused")
    if len(focused) != 1:
        raise ValueError("AeroSpace did not report one focused window")

    try:
        aerospace("flatten-workspace-tree", "--workspace", workspace)
        aerospace(
            "layout",
            "--root",
            "--workspace",
            workspace,
            "h_tiles" if count <= 2 else "v_tiles",
        )
        if count > 2:
            columns = isqrt(count - 1) + 1
            rows = (count + columns - 1) // columns
            row_size, extra = divmod(count, rows)
            offset = 0
            for row in range(rows):
                size = row_size + (row < extra)
                for column in range(1, size):
                    # DFS visits only tiling windows, in their actual tree order.
                    aerospace(
                        "focus",
                        "--dfs-index",
                        str(offset + column),
                        workspace=workspace,
                    )
                    if column == 1:
                        aerospace("join-with", "up", workspace=workspace)
                    else:
                        aerospace(
                            "move",
                            "up",
                            "--boundaries",
                            "workspace",
                            "--boundaries-action",
                            "stop",
                            workspace=workspace,
                        )
                offset += size
        aerospace("balance-sizes", "--workspace", workspace)
    finally:
        if count > 2:
            aerospace("focus", "--window-id", str(focused[0]))


def main():
    try:
        arrange_grid()
    except subprocess.CalledProcessError as error:
        print(
            f"AeroSpace grid failed: {error.stderr.strip() or error}", file=sys.stderr
        )
        return 1
    except (OSError, ValueError) as error:
        print(f"AeroSpace grid failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
