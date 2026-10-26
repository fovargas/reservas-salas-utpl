from dataclasses import dataclass

import pytest

from app.services import usuarios as usuarios_service
from app.services.usuarios import EmailYaRegistradoError, CredencialesInvalidasError
from app.security import hash_password


@dataclass
class UsuarioFalso:
    id: int
    email: str
    hashed_password: str


class RepositorioUsuariosFalso:
    def __init__(self):
        self._usuarios: dict[str, UsuarioFalso] = {}
        self._siguiente_id = 1

    def obtener_por_email(self, db, email):
        return self._usuarios.get(email)

    def guardar(self, db, email, hashed_password):
        usuario = UsuarioFalso(id=self._siguiente_id, email=email, hashed_password=hashed_password)
        self._usuarios[email] = usuario
        self._siguiente_id += 1
        return usuario


def test_registrar_usuario_exitoso():
    repo = RepositorioUsuariosFalso()

    usuario = usuarios_service.registrar_usuario(None, "estudiante@utpl.edu.ec", "claveSegura123", repo=repo)

    assert usuario.email == "estudiante@utpl.edu.ec"
    assert usuario.hashed_password != "claveSegura123"


def test_registrar_usuario_email_duplicado_lanza_error():
    repo = RepositorioUsuariosFalso()
    usuarios_service.registrar_usuario(None, "docente@utpl.edu.ec", "claveSegura123", repo=repo)

    with pytest.raises(EmailYaRegistradoError):
        usuarios_service.registrar_usuario(None, "docente@utpl.edu.ec", "otraClave456", repo=repo)


def test_autenticar_usuario_exitoso():
    repo = RepositorioUsuariosFalso()
    repo.guardar(None, "docente@utpl.edu.ec", hash_password("claveSegura123"))

    usuario = usuarios_service.autenticar_usuario(None, "docente@utpl.edu.ec", "claveSegura123", repo=repo)

    assert usuario.email == "docente@utpl.edu.ec"


def test_autenticar_usuario_credenciales_invalidas_lanza_error():
    repo = RepositorioUsuariosFalso()
    repo.guardar(None, "docente@utpl.edu.ec", hash_password("claveSegura123"))

    with pytest.raises(CredencialesInvalidasError):
        usuarios_service.autenticar_usuario(None, "docente@utpl.edu.ec", "claveIncorrecta", repo=repo)


def test_autenticar_usuario_inexistente_lanza_error():
    with pytest.raises(CredencialesInvalidasError):
        usuarios_service.autenticar_usuario(None, "nadie@utpl.edu.ec", "claveSegura123", repo=RepositorioUsuariosFalso())
