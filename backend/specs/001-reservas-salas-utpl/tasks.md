# tasks.md — Reservas de Salas UTPL

Cada tarea se da por terminada solo con: (1) código escrito, (2) test
correspondiente escrito y en verde, (3) sin violar ningún artículo de
`.specify/memory/constitution.md` aplicable a esa capa.

## Fase 0 — Infraestructura de proyecto
- [x] T00.1 `pyproject.toml` con dependencias, `[tool.coverage.run] omit`, `[tool.ruff]`
- [x] T00.2 `.env.example` / `.env` con `SECRET_KEY`, `DATABASE_URL`, `ACCESS_TOKEN_EXPIRE_MINUTES`, `LOG_LEVEL`, `MCP_DEMO_EMAIL`, `MCP_DEMO_PASSWORD`
- [x] T00.3 `.gitignore`

## Fase 1 — Models (Artículo I.3, III)
- [x] T01.1 `app/models/usuario.py::Usuario`
- [x] T01.2 `app/models/reserva.py::Reserva` (FK `usuario_id`)

## Fase 2 — Schemas (Artículo V.3)
- [x] T02.1 `app/schemas/usuario.py`: `UsuarioCreate`, `UsuarioResponse`
- [x] T02.2 `app/schemas/reserva.py`: `ReservaCreate`, `ReservaResponse`

## Fase 3 — Utils (Artículo II.2, OCP)
- [x] T03.1 `app/utils/validadores.py`: `SALAS_VALIDAS`, `sala_valida`, `horario_valido`, `se_solapan`
  - Tests: `tests/test_validadores.py` (8 tests)

## Fase 4 — Repositories (Artículo I.3, solo persistencia)
- [x] T04.1 `app/repositories/usuarios.py`
- [x] T04.2 `app/repositories/reservas.py` (incluye `existe_solapamiento`)
  - Cubierto por `tests/test_integracion_reservas.py`

## Fase 5 — Services: reglas de negocio (Artículo II.1, II.3, VII.2)
- [x] T05.1 `app/services/usuarios.py`
- [x] T05.2 `app/services/reservas.py`
  - **4 tests unitarios obligatorios (uno por regla de negocio), `RepositorioFalso`, sin `unittest.mock`:**
    1. `test_crear_reserva_sala_invalida_lanza_error` ✅
    2. `test_crear_reserva_horario_invertido_lanza_error` ✅
    3. `test_crear_reserva_solapada_lanza_error` ✅
    4. `test_cancelar_reserva_ajena_lanza_error` ✅
  - Archivo: `tests/test_reservas.py` (10 tests, incluye casos exitosos y de borde)
  - `tests/test_usuarios_service.py` (5 tests adicionales)

## Fase 6 — Dependencies + Auth (Artículo IV.4)
- [x] T06.1 `app/security.py`
- [x] T06.2 `app/dependencies.py`: `get_current_user`, `get_reservas_repo`

## Fase 7 — Routers (Artículo V)
- [x] T07.1 `app/routers/usuarios.py`
- [x] T07.2 `app/routers/reservas.py`
  - Cubierto por `tests/test_api_reservas.py` y `tests/test_api_usuarios.py` — los 6 casos de error de `spec.md` en verde

## Fase 8 — MCP (Artículo VI)
- [x] T08.1 `app/mcp/tools/reservas.py`: `crear_reserva`, `listar_reservas`, `cancelar_reserva` (con `confirmar`)
- [x] T08.2 `app/mcp/server.py`
  - Verificado directamente vía `mcp.call_tool(...)` en `tests/test_mcp_reservas.py` (5 tests: éxito + error por cada tool relevante)
  - Verificado manualmente en vivo contra `uv run uvicorn app.main:app`: `POST /usuarios/` → login → `POST /reservas/` → 401 sin token → 400 solapamiento → `GET /reservas/`

## Fase 9 — Persistencia real + integración (Artículo III, VII.4)
- [x] T09.1 `app/database.py`, `app/config.py`
- [x] T09.2 Alembic: migración inicial (`usuarios`, `reservas`) aplicada
  - `tests/test_integracion_reservas.py` (3 tests contra SQLite en memoria real)

## Fase 10 — API end-to-end + dependency_overrides (Artículo VII.5)
- [x] T10.1 `app/main.py`: monta routers + MCP + logging + exception handler
  - `tests/test_api_reservas.py` (11 tests) + `tests/test_api_usuarios.py` (7 tests)
  - `tests/conftest.py`: `client` compartido (scope="session") — necesario porque `StreamableHTTPSessionManager.run()` solo se puede llamar una vez por instancia de `app`

## Fase 11 — Verificación final (Artículo VII.3)
- [x] T11.1 `uv run pytest --cov=app --cov-report=term-missing`: **49 passed**, cobertura total **95%**
  - `services/reservas.py` 100%, `services/usuarios.py` 100% (umbral: ≥90%)
  - Conjunto del proyecto 95% (umbral: ≥70%)
  - Los 4 tests de reglas de negocio + 6 casos de error de API: todos en verde
- [x] T11.2 `uv run ruff check .`: **All checks passed!**
- [x] T11.3 Checklist de Requisitos Mínimos verificada (ver README.md, sección "Checklist de requisitos mínimos")
