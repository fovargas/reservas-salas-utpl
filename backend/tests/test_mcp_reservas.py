import asyncio
import json

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

import app.mcp.tools.reservas as reservas_tools
from app.database import Base
from app.mcp.server import mcp


@pytest.fixture
def db_en_memoria(monkeypatch):
    """Aísla cada test de la base de datos real (reservas.db): parchea el
    SessionLocal que usa el tool para que abra sesiones contra SQLite en
    memoria, con las tablas ya creadas."""
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    TestSessionLocal = sessionmaker(bind=engine)
    monkeypatch.setattr(reservas_tools, "SessionLocal", TestSessionLocal)
    yield


def _llamar(nombre_tool: str, argumentos: dict) -> dict:
    resultado = asyncio.run(mcp.call_tool(nombre_tool, argumentos))
    bloques = resultado[0] if isinstance(resultado, tuple) else resultado
    return json.loads(bloques[0].text)


def test_tool_crear_reserva_exitoso(db_en_memoria):
    data = _llamar(
        "crear_reserva",
        {
            "sala": "aula_magna",
            "fecha": "2026-11-01",
            "hora_inicio": "08:00:00",
            "hora_fin": "09:00:00",
            "motivo": "prueba MCP",
        },
    )

    assert data["sala"] == "aula_magna"
    assert "error" not in data


def test_tool_crear_reserva_sala_invalida_devuelve_error(db_en_memoria):
    data = _llamar(
        "crear_reserva",
        {
            "sala": "cancha_futbol_inexistente",
            "fecha": "2026-11-01",
            "hora_inicio": "08:00:00",
            "hora_fin": "09:00:00",
        },
    )

    assert "error" in data


def test_tool_listar_reservas(db_en_memoria):
    _llamar(
        "crear_reserva",
        {"sala": "aula_magna", "fecha": "2026-11-01", "hora_inicio": "08:00:00", "hora_fin": "09:00:00"},
    )

    resultado = asyncio.run(mcp.call_tool("listar_reservas", {}))
    _, estructurado = resultado if isinstance(resultado, tuple) else (resultado, {"result": []})

    lista = estructurado["result"] if isinstance(estructurado, dict) and "result" in estructurado else estructurado
    assert len(lista) == 1


def test_tool_cancelar_reserva_sin_confirmar_devuelve_error(db_en_memoria):
    creada = _llamar(
        "crear_reserva",
        {"sala": "aula_magna", "fecha": "2026-11-01", "hora_inicio": "08:00:00", "hora_fin": "09:00:00"},
    )

    data = _llamar("cancelar_reserva", {"reserva_id": creada["id"], "confirmar": False})

    assert "error" in data


def test_tool_cancelar_reserva_confirmada_exitosa(db_en_memoria):
    creada = _llamar(
        "crear_reserva",
        {"sala": "aula_magna", "fecha": "2026-11-01", "hora_inicio": "08:00:00", "hora_fin": "09:00:00"},
    )

    data = _llamar("cancelar_reserva", {"reserva_id": creada["id"], "confirmar": True})

    assert data["cancelada"] is True
