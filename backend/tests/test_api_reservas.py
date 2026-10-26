import pytest

from app.main import app
from app.dependencies import get_current_user, get_reservas_repo
from app.models.usuario import Usuario
from tests.test_reservas import RepositorioFalso

USUARIO_A = Usuario(id=1, email="docente_a@utpl.edu.ec", hashed_password="no-importa")
USUARIO_B = Usuario(id=2, email="docente_b@utpl.edu.ec", hashed_password="no-importa")

RESERVA_VALIDA = {
    "sala": "aula_magna",
    "fecha": "2026-10-05",
    "hora_inicio": "08:00:00",
    "hora_fin": "09:00:00",
    "motivo": "Reunión de coordinación",
}


# El fixture "client" (compartido por toda la suite) vive en tests/conftest.py.
@pytest.fixture
def autenticado_como_a():
    repo = RepositorioFalso()
    app.dependency_overrides[get_current_user] = lambda: USUARIO_A
    app.dependency_overrides[get_reservas_repo] = lambda: repo
    yield repo
    app.dependency_overrides.pop(get_current_user, None)
    app.dependency_overrides.pop(get_reservas_repo, None)


def test_crear_reserva_exitosa(client, autenticado_como_a):
    response = client.post("/reservas/", json=RESERVA_VALIDA)

    assert response.status_code == 201
    assert response.json()["sala"] == "aula_magna"


def test_listar_reservas_exitoso(client, autenticado_como_a):
    client.post("/reservas/", json=RESERVA_VALIDA)

    response = client.get("/reservas/")

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_crear_reserva_sala_invalida_devuelve_400(client, autenticado_como_a):
    datos = {**RESERVA_VALIDA, "sala": "cancha_futbol_inexistente"}

    response = client.post("/reservas/", json=datos)

    assert response.status_code == 400


def test_crear_reserva_horario_invertido_devuelve_400(client, autenticado_como_a):
    datos = {**RESERVA_VALIDA, "hora_inicio": "10:00:00", "hora_fin": "09:00:00"}

    response = client.post("/reservas/", json=datos)

    assert response.status_code == 400


def test_crear_reserva_solapada_devuelve_400(client, autenticado_como_a):
    client.post("/reservas/", json=RESERVA_VALIDA)

    response = client.post("/reservas/", json=RESERVA_VALIDA)

    assert response.status_code == 400
    assert "solapad" in response.json()["detail"].lower() or "ya está reservada" in response.json()["detail"]


def test_crear_reserva_sin_token_devuelve_401(client):
    response = client.post("/reservas/", json=RESERVA_VALIDA)

    assert response.status_code == 401


def test_listar_reservas_sin_token_devuelve_401(client):
    response = client.get("/reservas/")

    assert response.status_code == 401


def test_cancelar_reserva_ajena_devuelve_403(client):
    repo = RepositorioFalso()

    app.dependency_overrides[get_current_user] = lambda: USUARIO_A
    app.dependency_overrides[get_reservas_repo] = lambda: repo
    creada = client.post("/reservas/", json=RESERVA_VALIDA)
    reserva_id = creada.json()["id"]

    app.dependency_overrides[get_current_user] = lambda: USUARIO_B
    response = client.delete(f"/reservas/{reserva_id}")

    app.dependency_overrides.pop(get_current_user, None)
    app.dependency_overrides.pop(get_reservas_repo, None)

    assert response.status_code == 403


def test_cancelar_reserva_inexistente_devuelve_404(client, autenticado_como_a):
    response = client.delete("/reservas/9999")

    assert response.status_code == 404


def test_cancelar_reserva_propia_devuelve_204(client, autenticado_como_a):
    creada = client.post("/reservas/", json=RESERVA_VALIDA)
    reserva_id = creada.json()["id"]

    response = client.delete(f"/reservas/{reserva_id}")

    assert response.status_code == 204


class RepositorioRoto:
    """Simula un fallo inesperado del repositorio (ej. la DB se cae a mitad de la request)."""

    def existe_solapamiento(self, db, sala, fecha, hora_inicio, hora_fin):
        raise RuntimeError("la base de datos no responde")


def test_error_no_controlado_devuelve_500_sin_stacktrace(client):
    app.dependency_overrides[get_current_user] = lambda: USUARIO_A
    app.dependency_overrides[get_reservas_repo] = lambda: RepositorioRoto()

    response = client.post("/reservas/", json=RESERVA_VALIDA)

    app.dependency_overrides.pop(get_current_user, None)
    app.dependency_overrides.pop(get_reservas_repo, None)

    assert response.status_code == 500
    assert response.json() == {"detail": "Error interno del servidor"}
