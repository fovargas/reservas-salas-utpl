from datetime import date, time

import pytest

from app.services import reservas as reservas_service
from app.services.reservas import (
    SalaInvalidaError,
    HorarioInvalidoError,
    SolapamientoError,
    ReservaNoEncontradaError,
    ReservaAjenaError,
)
from app.utils.validadores import se_solapan

SALA = "aula_magna"
FECHA = date(2026, 10, 1)


class RepositorioFalso:
    """Test double: mismo contrato que app/repositories/reservas.py, sin persistencia real."""

    def __init__(self):
        self._reservas: list[dict] = []
        self._siguiente_id = 1

    def guardar(self, db, usuario_id, sala, fecha, hora_inicio, hora_fin, motivo):
        reserva = {
            "id": self._siguiente_id,
            "usuario_id": usuario_id,
            "sala": sala,
            "fecha": fecha,
            "hora_inicio": hora_inicio,
            "hora_fin": hora_fin,
            "motivo": motivo,
        }
        self._reservas.append(reserva)
        self._siguiente_id += 1
        return reserva

    def listar(self, db, usuario_id, skip=0, limit=20):
        propias = [r for r in self._reservas if r["usuario_id"] == usuario_id]
        return propias[skip : skip + limit]

    def obtener_por_id(self, db, reserva_id):
        return next((r for r in self._reservas if r["id"] == reserva_id), None)

    def existe_solapamiento(self, db, sala, fecha, hora_inicio, hora_fin):
        return any(
            r["sala"] == sala
            and r["fecha"] == fecha
            and se_solapan(hora_inicio, hora_fin, r["hora_inicio"], r["hora_fin"])
            for r in self._reservas
        )

    def eliminar(self, db, reserva_id):
        self._reservas = [r for r in self._reservas if r["id"] != reserva_id]

    def listar_por_sala_y_fecha(self, db, sala, fecha):
        return sorted(
            (r for r in self._reservas if r["sala"] == sala and r["fecha"] == fecha),
            key=lambda r: r["hora_inicio"],
        )

    def listar_entre_fechas(self, db, desde, hasta):
        return [r for r in self._reservas if desde <= r["fecha"] <= hasta]


# Gracias a DIP: se inyecta un repositorio falso, no se necesita unittest.mock.
def test_crear_reserva_exitosa():
    repo = RepositorioFalso()

    resultado = reservas_service.crear_reserva(
        None, 1, SALA, FECHA, time(8, 0), time(9, 0), "Reunión de coordinación", repo=repo
    )

    assert resultado["sala"] == SALA
    assert repo.listar(None, 1) == [resultado]


def test_crear_reserva_sala_invalida_lanza_error():
    with pytest.raises(SalaInvalidaError):
        reservas_service.crear_reserva(
            None, 1, "cancha_futbol_inexistente", FECHA, time(8, 0), time(9, 0), repo=RepositorioFalso()
        )


def test_crear_reserva_horario_invertido_lanza_error():
    with pytest.raises(HorarioInvalidoError):
        reservas_service.crear_reserva(
            None, 1, SALA, FECHA, time(10, 0), time(9, 0), repo=RepositorioFalso()
        )


def test_crear_reserva_horario_igual_lanza_error():
    with pytest.raises(HorarioInvalidoError):
        reservas_service.crear_reserva(
            None, 1, SALA, FECHA, time(9, 0), time(9, 0), repo=RepositorioFalso()
        )


def test_crear_reserva_solapada_lanza_error():
    repo = RepositorioFalso()
    reservas_service.crear_reserva(None, 1, SALA, FECHA, time(8, 0), time(10, 0), repo=repo)

    with pytest.raises(SolapamientoError):
        reservas_service.crear_reserva(None, 2, SALA, FECHA, time(9, 0), time(11, 0), repo=repo)


def test_crear_reserva_horario_contiguo_no_se_solapa():
    """[08:00,10:00) y [10:00,11:00) no se solapan -- ver spec.md, Clarifications."""
    repo = RepositorioFalso()
    reservas_service.crear_reserva(None, 1, SALA, FECHA, time(8, 0), time(10, 0), repo=repo)

    resultado = reservas_service.crear_reserva(None, 2, SALA, FECHA, time(10, 0), time(11, 0), repo=repo)

    assert resultado["hora_inicio"] == time(10, 0)


def test_crear_reserva_otra_sala_mismo_horario_no_se_solapa():
    repo = RepositorioFalso()
    reservas_service.crear_reserva(None, 1, SALA, FECHA, time(8, 0), time(10, 0), repo=repo)

    resultado = reservas_service.crear_reserva(
        None, 2, "laboratorio_redes", FECHA, time(8, 0), time(10, 0), repo=repo
    )

    assert resultado["sala"] == "laboratorio_redes"


def test_cancelar_reserva_ajena_lanza_error():
    repo = RepositorioFalso()
    reserva = reservas_service.crear_reserva(None, 1, SALA, FECHA, time(8, 0), time(9, 0), repo=repo)

    with pytest.raises(ReservaAjenaError):
        reservas_service.cancelar_reserva(None, 2, reserva["id"], repo=repo)


def test_cancelar_reserva_inexistente_lanza_error():
    with pytest.raises(ReservaNoEncontradaError):
        reservas_service.cancelar_reserva(None, 1, 999, repo=RepositorioFalso())


def test_cancelar_reserva_propia_exitosa():
    repo = RepositorioFalso()
    reserva = reservas_service.crear_reserva(None, 1, SALA, FECHA, time(8, 0), time(9, 0), repo=repo)

    reservas_service.cancelar_reserva(None, 1, reserva["id"], repo=repo)

    assert repo.listar(None, 1) == []
