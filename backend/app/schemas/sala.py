from datetime import time

from pydantic import BaseModel


class SalaResponse(BaseModel):
    id: str
    nombre: str
    edificio: str
    tipo: str
    capacidad: int
    equipamiento: list[str]


class FranjaOcupada(BaseModel):
    hora_inicio: time
    hora_fin: time
    propia: bool
