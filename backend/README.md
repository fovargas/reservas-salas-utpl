# Reservas de Salas UTPL

Proyecto Integrador — MOD2: Programación de Backend y MCP en Python para IA
Generativa. Backend de reservas de espacios compartidos del campus UTPL
(salas de reuniones, auditorio, laboratorios, aula magna), construido con
arquitectura en capas, REST + MCP sobre el mismo `services/`, autenticación
OAuth2 + JWT, y Spec-Driven Development.

Idea elegida del menú del Proyecto Integrador: **#5 — Reservas de un
espacio**, aplicada al contexto UTPL (catálogo fijo de salas del campus en
vez de un consultorio/cancha genérico).

## Artefactos de Spec-Driven Development

- [`.specify/memory/constitution.md`](.specify/memory/constitution.md) — reglas no negociables (arquitectura, SOLID, seguridad, MCP, testing)
- [`specs/001-reservas-salas-utpl/spec.md`](specs/001-reservas-salas-utpl/spec.md) — entidades, reglas de negocio, contrato REST + MCP
- [`specs/001-reservas-salas-utpl/plan.md`](specs/001-reservas-salas-utpl/plan.md) — stack técnico y trazabilidad hacia la constitución
- [`specs/001-reservas-salas-utpl/tasks.md`](specs/001-reservas-salas-utpl/tasks.md) — tareas atómicas, cada una con su test

## Arquitectura

```
app/
├── main.py          # FastAPI + montaje de MCP + logging + exception handler
├── config.py         # Settings (pydantic-settings, lee .env)
├── database.py        # engine, SessionLocal, get_db
├── security.py        # hash de contraseñas, JWT
├── dependencies.py     # get_current_user, get_reservas_repo
├── logging_config.py
├── routers/           # HTTP <-> services (sin reglas de negocio)
│   ├── usuarios.py
│   └── reservas.py
├── services/           # reglas de negocio, DIP (repo por parámetro)
│   ├── usuarios.py
│   └── reservas.py
├── repositories/        # persistencia (SQLAlchemy), sin reglas de negocio
│   ├── usuarios.py
│   └── reservas.py
├── models/            # SQLAlchemy
│   ├── usuario.py
│   └── reserva.py
├── schemas/            # Pydantic in/out
│   ├── usuario.py
│   └── reserva.py
├── utils/
│   └── validadores.py   # SALAS_VALIDAS, sala_valida, horario_valido, se_solapan
└── mcp/
    ├── server.py        # FastMCP, montado como sub-app ASGI en main.py
    ├── auth.py          # JWTTokenVerifier (reutiliza el JWT de REST)
    └── tools/
        └── reservas.py    # tools MCP -- reutilizan services/reservas.py

tests/
├── conftest.py            # cliente de API compartido (StreamableHTTPSessionManager.run() una sola vez)
├── test_reservas.py         # unitarios services/reservas.py (RepositorioFalso, sin mock)
├── test_usuarios_service.py   # unitarios services/usuarios.py
├── test_validadores.py       # unitarios utils/
├── test_integracion_reservas.py # integración contra SQLite real en memoria
├── test_api_reservas.py       # API con dependency_overrides
├── test_api_usuarios.py       # API: registro, login, flujo completo
└── test_mcp_reservas.py       # tools MCP invocados directamente vía mcp.call_tool()
```

## Regla de negocio central: catálogo de salas + solapamiento

`sala` es un campo de texto validado contra un catálogo fijo
(`app/utils/validadores.py::SALAS_VALIDAS`) — el mismo patrón OCP que usó
`CATEGORIAS_PERMITIDAS` en el ejemplo guiado de "Gastos", en vez de una
entidad `Sala` con su propio CRUD (fuera del alcance del proyecto). El
solapamiento se evalúa por sala + fecha + horario, con intersección
estricta de intervalos (`app/utils/validadores.py::se_solapan`) — ver
`spec.md`, sección "Clarifications", para el caso borde de horarios
contiguos.

## Cómo correr el proyecto

```bash
uv sync
cp .env.example .env   # ya existe un .env de desarrollo con un SECRET_KEY generado
uv run alembic upgrade head
uv run uvicorn app.main:app --reload
```

Abre `http://127.0.0.1:8000/docs` y prueba: `POST /usuarios/` → `POST
/usuarios/token` → autorizar con el token → `POST /reservas/` → `GET
/reservas/` → `DELETE /reservas/{id}`.

### MCP (Inspector, transporte stdio)

```bash
uv run mcp dev app/mcp/server.py
```

### MCP sobre HTTP (mismo proceso que REST, con el JWT de la Sesión 7/8)

Con el servidor corriendo, MCP queda montado en `http://127.0.0.1:8000/mcp/`,
protegido con el mismo JWT que emite `POST /usuarios/token`.

## Tests y cobertura

```bash
uv run pytest --cov=app --cov-report=term-missing -v
uv run ruff check .
```

Estado actual: **65 tests, todos en verde**. Cobertura: `services/` 100%
(umbral constitución: ≥90%), conjunto del proyecto 95% (umbral: ≥70%).

## Checklist de requisitos mínimos (Proyecto Integrador)

### Arquitectura
- [x] Monolito modular con capas: `routers/`, `mcp/`, `services/`, `repositories/`, `models/`, `schemas/`, `utils/`
- [x] `services/` recibe el repository como parámetro (DIP) — ver `app/services/reservas.py` (`repo=reservas_repository` en cada función)
- [x] Al menos 1 regla de negocio real en `services/` — en realidad 4: sala válida, horario válido, no-solapamiento, propiedad de la reserva (`app/services/reservas.py`)

### Seguridad
- [x] OAuth2 + JWT con `Usuario` propio (`app/security.py`, `app/dependencies.py`)
- [x] Contraseñas hasheadas con bcrypt (`app/security.py::hash_password`)
- [x] Secretos en `.env` + `pydantic-settings`, `.env` fuera de Git (`.gitignore`)
- [x] `.env.example` versionado sin valores reales
- [x] Endpoints de `Reserva` protegidos — sin token, 401 (`tests/test_api_reservas.py::test_crear_reserva_sin_token_devuelve_401`)

### REST + MCP
- [x] CRUD completo vía REST para `Reserva` (crear, listar, cancelar — `app/routers/reservas.py`)
- [x] 3 tools MCP (`crear_reserva`, `listar_reservas`, `cancelar_reserva`) que reutilizan `services/reservas.py` sin duplicar lógica (`app/mcp/tools/reservas.py`)
- [x] Manejo de errores consistente: `HTTPException` en REST, `{"error": "..."}` en MCP
- [x] Descripciones de tools específicas (ver docstrings en `app/mcp/tools/reservas.py`)
- [x] Identidad en MCP resuelta desde el JWT verificado sobre HTTP; usuario demo documentado como fallback explícito solo para stdio (`_resolver_usuario_actual`, `_obtener_o_crear_usuario_demo`)
- [x] `cancelar_reserva` (acción destructiva) exige `confirmar=True` gestionado por el servidor, no por criterio del modelo (Artículo VI.5)

### Testing
- [x] Un test unitario por cada regla de negocio explícita de `spec.md` (4 reglas → 4 tests mínimo, hay más cubriendo bordes) — `tests/test_reservas.py`
- [x] Repository falso inyectado por parámetro, nunca `unittest.mock`
- [x] Cobertura `services/` ≥90% (real: 100%), global ≥70% (real: 95%)
- [x] Tests de integración contra base de datos real — `tests/test_integracion_reservas.py`
- [x] Tests de tools MCP verificados directamente (`tests/test_mcp_reservas.py`) y manualmente con MCP Inspector

### Spec-Driven Development
- [x] `constitution.md` con arquitectura en capas + Repository, autenticación obligatoria, gestión de secretos, estándar de testing
- [x] `spec.md` con entidades, reglas de negocio, contrato REST + MCP, casos de error explícitos y sección de Clarifications
- [x] `plan.md` con trazabilidad hacia cada artículo de la constitución
- [x] `tasks.md` con tareas atómicas, cada una con su test, marcadas como completadas
