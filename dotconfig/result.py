from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar("T")
E = TypeVar("E")
U = TypeVar("U")


@dataclass(frozen=True)
class Ok(Generic[T]):
    value: T
    ok: bool = True

    def __bool__(self) -> bool:
        return True


@dataclass(frozen=True)
class Err(Generic[E]):
    error: E
    ok: bool = False

    def __bool__(self) -> bool:
        return False


type Result[T, E] = Ok[T] | Err[E]
