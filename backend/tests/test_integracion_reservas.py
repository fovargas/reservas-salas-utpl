from datetime import date, time

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base
from app.repositories import usuarios as usuarios_repository
from app.repositories import reservas as reservas_repository
from app.services import reservas as reservas_service
from app.services.reservas import SolapamientoError

SALA = "sala_reuniones_biblioteca"
FECHA = date(2026, 10, 5)


@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    yield db
    db.close()


def test_crear_y_listar_reserva_integracion(db_session):
    usuario = usuarios_repository.guardar(db_session, "docente@utpl.edu.ec", "hash-de-prueba")

    reservas_service.crear_reserva(
        db_session, usuario.id, SALA, FECHA, time(8, 0), time(9, 0), "Reunión de área", repo=reservas_repository
    )

    reservas = reservas_service.listar_reservas(db_session, usuario.id, repo=reservas_repository)

    assert len(reservas) == 1
    assert reservas[0]["sala"] == SALA


def test_solapamiento_contra_base_de_datos_real_integracion(db_session):
    usuario_a = usuarios_repository.guardar(db_session, "docente_a@utpl.edu.ec", "hash-de-prueba")
    usuario_b = usuarios_repository.guardar(db_session, "docente_b@utpl.edu.ec", "hash-de-prueba")

    reservas_service.crear_reserva(
        db_session, usuario_a.id, SALA, FECHA, time(8, 0), time(10, 0), repo=reservas_repository
    )

    with pytest.raises(SolapamientoError):
        reservas_service.crear_reserva(
            db_session, usuario_b.id, SALA, FECHA, time(9, 0), time(11, 0), repo=reservas_repository
        )


def test_cancelar_reserva_integracion(db_session):
    usuario = usuarios_repository.guardar(db_session, "docente@utpl.edu.ec", "hash-de-prueba")
    reserva = reservas_service.crear_reserva(
        db_session, usuario.id, SALA, FECHA, time(8, 0), time(9, 0), repo=reservas_repository
    )

    reservas_service.cancelar_reserva(db_session, usuario.id, reserva["id"], repo=reservas_repository)

    assert reservas_service.listar_reservas(db_session, usuario.id, repo=reservas_repository) == []
