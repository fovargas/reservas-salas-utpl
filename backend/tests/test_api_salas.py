import pytest

from app.dependencies import get_current_user, get_reservas_repo
from app.main import app
from app.utils.salas import CATALOGO_SALAS
from tests.test_api_reservas import USUARIO_A, USUARIO_B, RESERVA_VALIDA
from tests.test_reservas import RepositorioFalso


@pytest.fixture
def repo_compartido():
    repo = RepositorioFalso()
    app.dependency_overrides[get_reservas_repo] = lambda: repo
    yield repo
    app.dependency_overrides.pop(get_reservas_repo, None)
    app.dependency_overrides.pop(get_current_user, None)


def test_catalogo_tiene_al_menos_18_salas_con_ids_unicos():
    ids = [s["id"] for s in CATALOGO_SALAS]
    assert len(ids) >= 18
    assert len(ids) == len(set(ids))


def test_listar_salas_es_publico(client):
    response = client.get("/salas/")

    assert response.status_code == 200
    assert len(response.json()) == len(CATALOGO_SALAS)
    assert {"id", "nombre", "edificio", "tipo", "capacidad", "equipamiento"} <= response.json()[0].keys()


def test_obtener_sala_inexistente_devuelve_404(client):
    assert client.get("/salas/no_existe").status_code == 404


def test_ocupacion_sin_token_devuelve_401(client):
    response = client.get("/salas/aula_magna/ocupacion", params={"fecha": "2026-10-05"})

    assert response.status_code == 401


def test_ocupacion_fecha_invalida_devuelve_422(client, repo_compartido):
    app.dependency_overrides[get_current_user] = lambda: USUARIO_A

    response = client.get("/salas/aula_magna/ocupacion", params={"fecha": "mañana"})

    assert response.status_code == 422


def test_ocupacion_muestra_reservas_de_otros_sin_identificarlos(client, repo_compartido):
    app.dependency_overrides[get_current_user] = lambda: USUARIO_A
    client.post("/reservas/", json=RESERVA_VALIDA)

    app.dependency_overrides[get_current_user] = lambda: USUARIO_B
    response = client.get("/salas/aula_magna/ocupacion", params={"fecha": "2026-10-05"})

    assert response.status_code == 200
    assert response.json() == [{"hora_inicio": "08:00:00", "hora_fin": "09:00:00", "propia": False}]
