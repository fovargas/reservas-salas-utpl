from datetime import date, time

from pydantic import BaseModel, ConfigDict


class ReservaCreate(BaseModel):
    sala: str
    fecha: date
    hora_inicio: time
    hora_fin: time
    motivo: str | None = None


class ReservaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    sala: str
    fecha: date
    hora_inicio: time
    hora_fin: time
    motivo: str | None = None
