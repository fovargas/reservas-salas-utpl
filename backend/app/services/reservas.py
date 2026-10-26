import logging
from datetime import date, time

from app.repositories import reservas as reservas_repository
from app.utils.validadores import sala_valida, horario_valido

logger = logging.getLogger(__name__)


class SalaInvalidaError(Exception):
    pass


class HorarioInvalidoError(Exception):
    pass


class SolapamientoError(Exception):
    pass


class ReservaNoEncontradaError(Exception):
    pass


class ReservaAjenaError(Exception):
    pass


# SRP: esta función SOLO valida. No decide disponibilidad, no persiste.
def _validar_reserva(sala: str, hora_inicio: time, hora_fin: time) -> None:
    if not sala_valida(sala):
        raise SalaInvalidaError(f"'{sala}' no es una sala válida del campus")

    if not horario_valido(hora_inicio, hora_fin):
        raise HorarioInvalidoError("hora_fin debe ser posterior a hora_inicio")


# SRP: esta función SOLO orquesta (valida -> revisa disponibilidad -> persiste).
# DIP: recibe "repo" como parámetro en vez de importar reservas_repository
# fijo dentro del cuerpo -> se puede sustituir por un repositorio falso en tests.
def crear_reserva(
    db,
    usuario_id: int,
    sala: str,
    fecha: date,
    hora_inicio: time,
    hora_fin: time,
    motivo: str | None = None,
    repo=reservas_repository,
) -> dict:
    _validar_reserva(sala, hora_inicio, hora_fin)

    if repo.existe_solapamiento(db, sala, fecha, hora_inicio, hora_fin):
        logger.warning(
            "Reserva rechazada por solapamiento: usuario_id=%s sala=%s fecha=%s",
            usuario_id,
            sala,
            fecha,
        )
        raise SolapamientoError(
            f"La sala '{sala}' ya está reservada en ese horario el {fecha}"
        )

    reserva = repo.guardar(db, usuario_id, sala, fecha, hora_inicio, hora_fin, motivo)
    logger.info(
        "Reserva creada: usuario_id=%s reserva_id=%s sala=%s",
        usuario_id,
        reserva["id"],
        sala,
    )
    return reserva


def listar_reservas(db, usuario_id: int, skip: int = 0, limit: int = 20, repo=reservas_repository) -> list[dict]:
    return repo.listar(db, usuario_id, skip, limit)


def cancelar_reserva(db, usuario_id: int, reserva_id: int, repo=reservas_repository) -> None:
    reserva = repo.obtener_por_id(db, reserva_id)
    if reserva is None:
        raise ReservaNoEncontradaError(f"La reserva {reserva_id} no existe")

    if reserva["usuario_id"] != usuario_id:
        logger.warning(
            "Intento de cancelar reserva ajena: usuario_id=%s reserva_id=%s dueño_real=%s",
            usuario_id,
            reserva_id,
            reserva["usuario_id"],
        )
        raise ReservaAjenaError("No puedes cancelar una reserva que no es tuya")

    repo.eliminar(db, reserva_id)
    logger.info("Reserva cancelada: usuario_id=%s reserva_id=%s", usuario_id, reserva_id)
