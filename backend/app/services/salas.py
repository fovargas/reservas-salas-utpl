from datetime import date

from app.repositories import reservas as reservas_repository
from app.utils.salas import CATALOGO_SALAS, SALAS_POR_ID


class SalaNoEncontradaError(Exception):
    pass


def listar_salas() -> list[dict]:
    return CATALOGO_SALAS


def obtener_sala(sala_id: str) -> dict:
    sala = SALAS_POR_ID.get(sala_id)
    if sala is None:
        raise SalaNoEncontradaError(f"La sala '{sala_id}' no existe")
    return sala


# Disponibilidad compartida: muestra las franjas ocupadas por cualquier
# usuario, pero solo marca cuáles son propias (no expone quién reservó).
def ocupacion(db, sala_id: str, fecha: date, usuario_id: int, repo=reservas_repository) -> list[dict]:
    obtener_sala(sala_id)
    return [
        {
            "hora_inicio": r["hora_inicio"],
            "hora_fin": r["hora_fin"],
            "propia": r["usuario_id"] == usuario_id,
        }
        for r in repo.listar_por_sala_y_fecha(db, sala_id, fecha)
    ]
