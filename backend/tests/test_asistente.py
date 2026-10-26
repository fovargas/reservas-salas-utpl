import json
from datetime import date, time

import pytest

from app.dependencies import get_cliente_ia, get_current_user, get_reservas_repo
from app.ia.gemini import ErrorIA
from app.main import app
from app.services import asistente as asistente_service
from tests.test_api_reservas import USUARIO_A
from tests.test_reservas import RepositorioFalso

HOY = date(2026, 10, 5)


class ClienteIAFalso:
    def __init__(self, texto=None, error=False):
        self.texto = texto
        self.error = error
        self.mensajes = []

    def generar_json(self, instrucciones, mensaje):
        self.mensajes.append(mensaje)
        if self.error:
            raise ErrorIA("caído")
        return self.texto


def test_modo_basico_filtra_por_capacidad_y_tipo():
    resultado = asistente_service.responder(
        None, 1, "Necesito un laboratorio para 25 personas", None, hoy=HOY, repo=RepositorioFalso()
    )

    assert resultado["modo"] == "basico"
    assert resultado["salas_sugeridas"] == ["laboratorio_software"]


def test_modo_basico_prefiere_salas_con_menos_reservas():
    repo = RepositorioFalso()
    repo.guardar(None, 2, "sala_estudio_grupal_1", HOY, time(8), time(9), None)

    resultado = asistente_service.responder(None, 1, "sala para estudiar", None, hoy=HOY, repo=repo)

    assert resultado["salas_sugeridas"][0] == "sala_estudio_grupal_2"


def test_modo_ia_descarta_salas_inventadas_y_no_envia_identidades():
    repo = RepositorioFalso()
    repo.guardar(None, 2, "aula_magna", HOY, time(8), time(9), None)
    cliente = ClienteIAFalso(json.dumps({"respuesta": "Usa el Aula Magna", "salas_sugeridas": ["aula_magna", "sala_falsa"]}))

    resultado = asistente_service.responder(None, 1, "¿Dónde hago un evento?", cliente, hoy=HOY, repo=repo)

    assert resultado == {"respuesta": "Usa el Aula Magna", "modo": "ia", "salas_sugeridas": ["aula_magna"]}
    assert "usuario_id" not in cliente.mensajes[0]


@pytest.mark.parametrize("cliente", [ClienteIAFalso(error=True), ClienteIAFalso("no es json")])
def test_si_la_ia_falla_responde_en_modo_basico(cliente):
    resultado = asistente_service.responder(None, 1, "sala de reuniones", cliente, hoy=HOY, repo=RepositorioFalso())

    assert resultado["modo"] == "basico"


@pytest.fixture
def api_asistente():
    app.dependency_overrides[get_reservas_repo] = lambda: RepositorioFalso()
    app.dependency_overrides[get_cliente_ia] = lambda: None
    yield
    for dep in (get_reservas_repo, get_cliente_ia, get_current_user):
        app.dependency_overrides.pop(dep, None)


def test_asistente_sin_token_devuelve_401(client, api_asistente):
    assert client.post("/asistente/", json={"pregunta": "hola qué tal"}).status_code == 401


def test_asistente_pregunta_vacia_devuelve_422(client, api_asistente):
    app.dependency_overrides[get_current_user] = lambda: USUARIO_A

    assert client.post("/asistente/", json={"pregunta": ""}).status_code == 422


def test_asistente_responde_por_api(client, api_asistente):
    app.dependency_overrides[get_current_user] = lambda: USUARIO_A

    response = client.post("/asistente/", json={"pregunta": "auditorio para 300 personas"})

    assert response.status_code == 200
    assert response.json()["salas_sugeridas"] == ["aula_magna"]


def test_modo_basico_no_confunde_videoconferencia_con_auditorio():
    resultado = asistente_service.responder(
        None, 1, "sala con videoconferencia para 12 personas", None, hoy=HOY, repo=RepositorioFalso()
    )

    assert "auditorio_campus" not in resultado["salas_sugeridas"]
    assert "aula_magna" not in resultado["salas_sugeridas"]
