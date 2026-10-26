EMAIL = "estudiante@utpl.edu.ec"
PASSWORD = "claveSegura123"


# El fixture "client" (compartido por toda la suite) vive en tests/conftest.py.
def test_registrar_usuario_exitoso(client):
    response = client.post("/usuarios/", json={"email": EMAIL, "password": PASSWORD})

    assert response.status_code == 201
    assert response.json()["email"] == EMAIL
    assert "password" not in response.json()
    assert "hashed_password" not in response.json()


def test_registrar_usuario_email_duplicado_devuelve_400(client):
    client.post("/usuarios/", json={"email": "duplicado@utpl.edu.ec", "password": PASSWORD})

    response = client.post("/usuarios/", json={"email": "duplicado@utpl.edu.ec", "password": "otraClave456"})

    assert response.status_code == 400


def test_registrar_usuario_email_invalido_devuelve_422(client):
    response = client.post("/usuarios/", json={"email": "no-es-un-email", "password": PASSWORD})

    assert response.status_code == 422


def test_login_exitoso_devuelve_token(client):
    client.post("/usuarios/", json={"email": "login@utpl.edu.ec", "password": PASSWORD})

    response = client.post(
        "/usuarios/token", data={"username": "login@utpl.edu.ec", "password": PASSWORD}
    )

    assert response.status_code == 200
    assert response.json()["token_type"] == "bearer"
    assert response.json()["access_token"]


def test_login_credenciales_invalidas_devuelve_401(client):
    response = client.post(
        "/usuarios/token", data={"username": "no-existe@utpl.edu.ec", "password": "loquesea"}
    )

    assert response.status_code == 401


def test_endpoint_protegido_con_token_invalido_devuelve_401(client):
    response = client.get("/reservas/", headers={"Authorization": "Bearer token-invalido-o-alterado"})

    assert response.status_code == 401


def test_flujo_completo_login_y_crear_reserva(client):
    client.post("/usuarios/", json={"email": "flujo@utpl.edu.ec", "password": PASSWORD})
    login = client.post("/usuarios/token", data={"username": "flujo@utpl.edu.ec", "password": PASSWORD})
    token = login.json()["access_token"]

    response = client.post(
        "/reservas/",
        json={
            "sala": "laboratorio_redes",
            "fecha": "2026-12-01",
            "hora_inicio": "10:00:00",
            "hora_fin": "11:00:00",
        },
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 201
    assert response.json()["sala"] == "laboratorio_redes"


def test_usuarios_me_sin_token_devuelve_401(client):
    assert client.get("/usuarios/me").status_code == 401


def test_usuarios_me_con_token_devuelve_el_usuario(client):
    datos = {"email": "me@utpl.edu.ec", "password": "clave-segura-1"}
    client.post("/usuarios/", json=datos)
    token = client.post("/usuarios/token", data={"username": datos["email"], "password": datos["password"]}).json()["access_token"]

    response = client.get("/usuarios/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    assert response.json()["email"] == "me@utpl.edu.ec"
