from dataclasses import dataclass
from typing import Generic, TypeVar

from typing_extensions import Literal, Never

T = TypeVar("T")
E = TypeVar("E")
U = TypeVar("U")


@dataclass(frozen=True)
class Ok(Generic[T]):
    value: T
    ok: Literal[True] = True

    def __bool__(self) -> bool:
        return True


@dataclass(frozen=True)
class Err(Generic[E]):
    error: E
    ok: Literal[False] = False

    def __bool__(self) -> bool:
        return False


type Result[T, E] = Ok[T] | Err[E]


def expect_never(never: Never) -> None:
    pass
