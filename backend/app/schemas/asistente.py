from typing import Literal

from pydantic import BaseModel, Field


class PreguntaAsistente(BaseModel):
    pregunta: str = Field(min_length=3, max_length=500)


class RespuestaAsistente(BaseModel):
    respuesta: str
    modo: Literal["ia", "basico"]
    salas_sugeridas: list[str]
