import os
import shutil

from domain.config import Symlink
from result import Err, Ok, Result


def is_symlink_correct(symlink: Symlink) -> bool:
    dst = symlink.dst.expanduser()
    src = symlink.src.expanduser()
    return dst.is_symlink() and dst.resolve() == src.resolve()


def perform_symlink(symlink: Symlink, overwrite: bool = False) -> Result[None, str]:
    src = symlink.src.expanduser()
    dst = symlink.dst.expanduser()
    try:
        if is_symlink_correct(symlink):
            return Ok(None)

        if dst.exists() or dst.is_symlink():
            if not overwrite:
                response = input(f"Path {dst} already exists. Overwrite? (y/n): ")
                if response.lower() != "y":
                    return Err(f"Skipped: {dst} already exists")

            if dst.is_symlink():
                os.unlink(dst)
            elif dst.is_dir():
                shutil.rmtree(dst)
            else:
                dst.unlink()

        dst.parent.mkdir(parents=True, exist_ok=True)
        os.symlink(src, dst)
        return Ok(None)
    except Exception as e:
        return Err(f"Error creating symlink {symlink}: {e}")
