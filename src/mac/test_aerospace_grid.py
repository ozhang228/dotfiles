import contextlib
import importlib.util
import io
import json
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "aerospace_grid", Path(__file__).with_name("aerospace-grid.py")
)
grid = importlib.util.module_from_spec(spec)
spec.loader.exec_module(grid)


def leaves(nodes):
    return [
        window
        for node in nodes
        for window in (leaves(node) if isinstance(node, list) else [node])
    ]


class FakeAeroSpace:
    """Model native DFS, join-with, and move-into-row command behavior."""

    def __init__(self, *, tree, focused, floating, fail_move=False):
        self.tree = tree
        self.focused = focused
        self.floating = floating
        self.fail_move = fail_move
        self.workspace = "1"
        self.orientation = "h_tiles"
        self.row_weights = ()

    def run(self, arguments, **options):
        _, command, *args = arguments
        if (
            "AEROSPACE_WINDOW_ID" in options["env"]
            or options["env"].get("AEROSPACE_WORKSPACE", self.workspace)
            != self.workspace
        ):
            raise AssertionError("Inherited targets would override the focused window")
        output = ""
        match command:
            case "list-workspaces":
                output = json.dumps([{"workspace": self.workspace}])
            case "list-windows":
                windows = (
                    [self.focused]
                    if "--focused" in args
                    else [*reversed(leaves(self.tree)), *self.floating]
                )
                output = json.dumps(
                    [
                        {
                            "window-id": window,
                            "window-parent-container-layout": "floating"
                            if window in self.floating
                            else self.orientation,
                        }
                        for window in windows
                    ]
                )
            case "flatten-workspace-tree":
                self.tree = leaves(self.tree)
            case "layout":
                if "--root" not in args and self.focused in self.floating:
                    raise subprocess.CalledProcessError(
                        1, arguments, stderr="The window is non-tiling"
                    )
                self.orientation = args[-1]
            case "focus":
                self.focused = (
                    leaves(self.tree)[int(args[1])]
                    if args[0] == "--dfs-index"
                    else int(args[1])
                )
            case "join-with":
                if args != ["up"]:
                    raise AssertionError(arguments)
                index = self.tree.index(self.focused)
                self.tree[index - 1 : index + 1] = [
                    [self.tree[index - 1], self.focused]
                ]
            case "move":
                if self.fail_move:
                    raise subprocess.CalledProcessError(
                        1, arguments, stderr="window closed"
                    )
                if args != [
                    "up",
                    "--boundaries",
                    "workspace",
                    "--boundaries-action",
                    "stop",
                ]:
                    raise AssertionError(arguments)
                index = self.tree.index(self.focused)
                self.tree[index - 1].append(self.tree.pop(index))
            case "balance-sizes":
                self.row_weights = tuple(1 for _ in self.tree)
            case _:
                raise AssertionError(f"Unexpected command: {arguments}")
        if (
            "--workspace" in args
            and args[args.index("--workspace") + 1] != self.workspace
        ):
            raise AssertionError("The grid must remain on the focused workspace")
        return subprocess.CompletedProcess(arguments, 0, stdout=output, stderr="")


class GridTests(unittest.TestCase):
    def test_hotkey_balances_rows_and_preserves_floating_focus(self):
        for count, expected in (
            (4, [[1, 2], [3, 4]]),
            (5, [[1, 2, 3], [4, 5]]),
            (6, [[1, 2, 3], [4, 5, 6]]),
        ):
            with self.subTest(count=count):
                native = FakeAeroSpace(
                    tree=[1, [2, 3], *range(4, count + 1)],
                    focused=99,
                    floating=[99],
                )
                with (
                    patch.dict(
                        "os.environ",
                        {"AEROSPACE_WINDOW_ID": "99", "AEROSPACE_WORKSPACE": "other"},
                    ),
                    patch.object(grid.subprocess, "run", native.run),
                ):
                    status = grid.main()
                self.assertEqual(status, 0)
                self.assertEqual(native.tree, expected)
                self.assertEqual(native.row_weights, (1, 1))
                self.assertEqual(native.focused, 99)
                self.assertEqual(native.floating, [99])
                self.assertEqual(native.workspace, "1")

    def test_native_failure_is_reported_and_original_focus_is_restored(self):
        native = FakeAeroSpace(
            tree=[1, 2, 3, 4, 5], focused=5, floating=[99], fail_move=True
        )
        errors = io.StringIO()
        with (
            patch.object(grid.subprocess, "run", native.run),
            contextlib.redirect_stderr(errors),
        ):
            status = grid.main()
        self.assertEqual(status, 1)
        self.assertEqual(errors.getvalue(), "AeroSpace grid failed: window closed\n")
        self.assertEqual(native.focused, 5)
        self.assertEqual(native.floating, [99])


if __name__ == "__main__":
    unittest.main()
