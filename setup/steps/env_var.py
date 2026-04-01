from typing import Literal

from pydantic import BaseModel


class RequiredEnvVar(BaseModel):
    type: Literal["required"] = "required"
    key: str


EnvVar = RequiredEnvVar
