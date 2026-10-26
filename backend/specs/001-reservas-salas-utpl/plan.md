Stack: FastAPI, uvicorn[standard], SQLAlchemy + Alembic, pyjwt,
passlib[bcrypt] (bcrypt<4.1), pydantic-settings, email-validator,
python-multipart, SDK oficial "mcp" montado vía streamable-http, pytest +
pytest-cov + httpx, ruff.

## Trazabilidad plan → constitución

- La separación `routers/services/repositories/models/schemas/utils` +
  `mcp/` (Artículo I) se implementa como paquetes Python bajo `app/`, sin
  imports cruzados que violen la dirección de dependencia
  (routers → services → repositories; utils sin dependencias hacia adentro).
- DIP (Artículo II.3) se implementa con parámetros por defecto en las
  funciones de `services/reservas.py` y `services/usuarios.py`
  (`repo=reservas_repository`), no con un contenedor de inyección de
  dependencias externo.
- OCP (Artículo II.2): el catálogo de salas vive en
  `app/utils/validadores.py::SALAS_VALIDAS` (un `set`), igual que
  `CATEGORIAS_PERMITIDAS` en "Gastos" — agregar una sala nueva es agregar un
  valor, no tocar `_validar_reserva`.
- Seguridad (Artículo IV): `pyjwt` para JWT (una sola librería, sin
  ambigüedad), `passlib.context.CryptContext(schemes=["bcrypt"])` para
  hashing (con `bcrypt<4.1` fijado por el incidente conocido de
  passlib 1.7.4 / bcrypt 4.1+), `pydantic_settings.BaseSettings` leyendo
  `.env` para `SECRET_KEY`/`DATABASE_URL`. `email-validator` y
  `python-multipart` son dependencias transitivas obligatorias de
  `EmailStr` y `OAuth2PasswordRequestForm`.
- Autorización (Artículo IV.4): toda ruta y tool que opera sobre reservas
  depende de `get_current_user` (REST) o de `_resolver_usuario_actual`
  (MCP) para obtener `usuario_id`; ningún endpoint ni tool acepta
  `usuario_id` como parámetro de entrada.
- Solapamiento (regla de negocio central, `spec.md`): se implementa como
  `repositories/reservas.py::existe_solapamiento(db, sala, fecha,
  hora_inicio, hora_fin)`, una consulta SQL con la condición de
  intersección estricta de intervalos (`spec.md`, sección Clarifications);
  `services/reservas.py::crear_reserva` la invoca antes de guardar.
- Testing (Artículo VII) se implementa con fixtures de pytest para DB en
  memoria, `app.dependency_overrides` para tests de API (`httpx` como
  dependencia de `TestClient`), y `pytest-cov` con el umbral del Artículo
  VII.3 (services ≥90%, conjunto ≥70%) verificado como último paso de la
  implementación.
- MCP (Artículo VI) se monta dentro de la misma app FastAPI
  (`streamable-http`), reutilizando `decodificar_token` (mismo JWT de REST)
  para extraer la identidad del header `Authorization` de la sesión MCP.
  `cancelar_reserva` exige `confirmar=True` como parámetro explícito del
  tool (Artículo VI.5) — la confirmación vive en el servidor, no en que el
  modelo "decida preguntar".

## Orden de implementación (dirección de dependencia, Artículo I)
1. `models/` (Usuario, Reserva)
2. `schemas/` (Pydantic in/out)
3. `utils/validadores.py` (SALAS_VALIDAS, sala_valida, horario_valido)
4. `repositories/` (usuarios, reservas — solo persistencia)
5. `services/` (usuarios, reservas — reglas de negocio, DIP)
6. `dependencies.py` (get_current_user, get_reservas_repo)
7. `routers/` (usuarios, reservas)
8. `mcp/tools/reservas.py` + `mcp/server.py` (reutiliza services/)
9. Alembic: migración inicial
10. Tests (unitarios → integración → API) + verificación de cobertura
