import os
from pathlib import Path

from pydantic import BaseModel

from result import Err, Ok, Result


class Symlink(BaseModel):
    src: Path
    dst: Path


def perform_symlink(symlink: Symlink, overwrite: bool = False) -> Result[None, str]:
    src = symlink.src.expanduser()
    dst = symlink.dst.expanduser()
    try:
        if dst.exists() or dst.is_symlink():
            if not overwrite:
                response = input(f"Path {dst} already exists. Overwrite? (y/n): ")
                if response.lower() != "y":
                    return Err(f"Skipped: {dst} already exists")

            if dst.is_symlink():
                os.unlink(dst)
            elif dst.is_dir():
                dst.rmdir()
            else:
                dst.unlink()

        os.symlink(src, dst)
        return Ok(None)
    except Exception as e:
        return Err(f"Error creating symlink {symlink}: {e}")
