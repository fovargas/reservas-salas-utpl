import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app


@pytest.fixture(scope="session")
def db_engine():
    # StaticPool: TestClient despacha las requests async en otro hilo -- sin
    # esto, SQLite en memoria abriría una base distinta (vacía) por hilo.
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    return engine


@pytest.fixture(scope="session")
def client(db_engine):
    """Cliente de API compartido por TODOS los módulos de test.

    El servidor MCP montado en app/main.py solo permite llamar a
    session_manager.run() UNA vez por instancia (ver Sesión 8, Paso 6) --
    ese .run() se dispara cada vez que un TestClient entra al lifespan de
    `app`. Por eso este fixture es de scope="session" y vive en conftest.py:
    un solo TestClient para toda la suite, en vez de uno por archivo.
    """
    TestSessionLocal = sessionmaker(bind=db_engine)

    def _get_db_de_prueba():
        db = TestSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = _get_db_de_prueba
    # raise_server_exceptions=False: sin esto, el TestClient re-lanza la
    # excepción en vez de dejar que el exception_handler de la app la
    # convierta en 500.
    with TestClient(app, raise_server_exceptions=False) as test_client:
        yield test_client
    app.dependency_overrides.clear()
