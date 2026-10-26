<!--
Sync Impact Report:
- Version change: Unversioned draft → 1.0.0
- List of modified principles:
  - Artículo I — Arquitectura en capas → I. Arquitectura en Capas
  - Artículo II — SOLID aplicado (no teórico) → II. SOLID Aplicado (No Teórico)
  - Artículo III — Persistencia → III. Persistencia
  - Artículo IV — Seguridad (no negociable) → IV. Seguridad (No Negociable)
  - Artículo V — Diseño de endpoints REST → V. Diseño de Endpoints REST
  - Artículo VI — MCP: tools y reutilización → VI. MCP: Tools y Reutilización
  - Artículo VII — Testing y cobertura → VII. Testing y Cobertura
- Added sections:
  - Estructuración estándar bajo `## Core Principles`.
  - Formalización del procedimiento de enmiendas, política SemVer y criterios de verificación bajo `## Governance`.
  - Metadatos canónicos de versión, fecha de ratificación y última enmienda.
- Removed sections: Ninguna (todos los mandatos normativos previos se preservan íntegramente).
- Follow-up TODOs: Ninguno.
-->

# Reservas de Salas UTPL Constitution

## Core Principles

### I. Arquitectura en Capas
1. `routers/` reciben la solicitud HTTP, delegan al service correspondiente y traducen su resultado (o excepción) a una respuesta HTTP. Un router NUNCA valida reglas de negocio (ej. "la sala debe existir en el catálogo") — esa lógica vive en `services/`.
2. `services/` contienen toda la lógica de negocio. Un service NUNCA importa SQLAlchemy, `Session`, ni ningún detalle de persistencia directamente.
3. `repositories/` son la única capa autorizada a leer o escribir en la base de datos. Un repository no contiene reglas de negocio, solo operaciones de persistencia (guardar, listar, buscar, eliminar).
4. `utils/` son funciones puras (mismo input → mismo output, sin efectos secundarios), sin importar nada de `services/`, `routers/` ni `repositories/`.
5. `mcp/tools/` NUNCA reimplementan lógica de `services/`. Si una tool de MCP y un router necesitan la misma regla, ambos llaman al mismo service.

### II. SOLID Aplicado (No Teórico)
1. **SRP**: cada función de `services/` hace una sola cosa. La validación (`_validar_x`) está separada de la orquestación (`crear_x`).
2. **OCP**: agregar una sala nueva al catálogo del campus se hace agregando un valor a una constante (`SALAS_VALIDAS`), nunca reescribiendo un `if` ya existente.
3. **DIP**: todo service que necesite un repository lo recibe como parámetro con un valor por defecto (`def crear_reserva(..., repo=reservas_repo)`), nunca lo importa fijo dentro del cuerpo de la función. Esto es innegociable: es lo que permite testear sin `unittest.mock`.
4. No se fuerza LSP ni ISP si el proyecto no tiene jerarquías de clases ni interfaces formales — no agregar complejidad artificial para cumplir un principio que no aplica todavía.

### III. Persistencia
1. SQLAlchemy como ORM, Alembic para migraciones. Ninguna sentencia SQL cruda concatenada con strings.
2. SQLite en desarrollo; el código de `database.py` debe funcionar contra Postgres sin tocar `services/` ni `routers/` (usar `connect_args` condicional solo para SQLite).
3. Cada modelo con datos de usuario incluye `usuario_id` como FK. Ninguna consulta de datos de **Reserva** puede omitir el filtro por `usuario_id` cuando corresponde (listar reservas propias); la verificación de solapamiento sí consulta reservas de todos los usuarios sobre la misma sala — es una regla de disponibilidad del espacio físico, no de privacidad de datos.

### IV. Seguridad (No Negociable)
1. Contraseñas: hash con `passlib[bcrypt]`. Nunca se guarda ni se loguea una contraseña en texto plano.
2. Autenticación: OAuth2 password flow + JWT firmado con HS256. `ACCESS_TOKEN_EXPIRE_MINUTES` configurable, nunca infinito.
3. `SECRET_KEY` y `DATABASE_URL` viven solo en `.env` (nunca versionado). `.env.example` documenta las variables necesarias sin valores reales. `SECRET_KEY` se genera con `openssl rand -hex 32` o equivalente criptográficamente seguro, nunca escrito a mano.
4. Autorización: el `usuario_id` para filtrar, crear o cancelar una reserva SIEMPRE sale del token JWT decodificado (`get_current_user`), NUNCA de un parámetro de la URL, del body, ni de un query param. Esto aplica también a recursos ya existentes, no solo a la creación: cancelar una reserva por `id` primero verifica que esa reserva pertenece al usuario autenticado, antes de tocarla.
5. Un error no controlado (`Exception` genérica) devuelve `500` con `{"detail": "Error interno del servidor"}` — nunca un stack trace ni el mensaje de la excepción original al cliente. El detalle sí se loguea internamente.
6. Toda entrada de usuario se valida con schemas Pydantic antes de llegar a `services/`.

### V. Diseño de Endpoints REST
1. Convención de verbos y códigos: `POST` crea (`201`), `GET` lista/lee (`200`), `DELETE` elimina (`204`), fallo de autenticación (`401`), recurso no encontrado (`404`), error de validación de schema (`422`), error de regla de negocio conocido (`400` con `{"detail": "..."}`). `403` se reserva para cuando el recurso solicitado existe pero pertenece a otro usuario y la operación lo identifica por `id` explícito en la ruta (ej. `DELETE /reservas/{id}`); un listado (`GET /reservas/`) NUNCA devuelve `403` — simplemente filtra por el `usuario_id` del JWT.
2. Toda lista paginada expone `skip` y `limit` como query params, con valores por defecto razonables (`skip=0, limit=20`); valores inválidos (negativos, no numéricos) son error de schema (`422`).
3. Los schemas de entrada y salida son distintos (`ReservaCreate` vs `ReservaResponse`) — nunca se expone el modelo de SQLAlchemy directamente.

### VI. MCP: Tools y Reutilización
1. Cada tool de MCP llama a una función de `services/`, punto. Ejemplo: `crear_reserva` (tool) y `POST /reservas/` (router) llaman a la misma función `services/reservas.py::crear_reserva()`.
2. La descripción de cada tool es específica y accionable (ej. "Crea una reserva de una sala del campus UTPL, validando que no se solape con otra reserva existente para esa misma sala y horario"), nunca genérica ("maneja reservas").
3. Errores de negocio se devuelven como una estructura clara (`{"error": "..."}`), nunca como una excepción sin controlar que rompa la sesión del cliente MCP.
4. Si el transporte es `stdio` y no hay forma de propagar identidad real de usuario, se documenta explícitamente en el código como simplificación consciente (comentario), nunca como un olvido silencioso. Si el transporte es `streamable-http` y hay un token verificado, la tool DEBE usar la identidad de ese token (nunca un usuario demo hardcodeado) — el usuario demo es solo el fallback legítimo cuando no hay ningún token disponible.
5. `cancelar_reserva` (efecto destructivo) exige una confirmación explícita gestionada por el propio servidor (un segundo parámetro `confirmar: bool` que debe llegar en `True`, verificado en el tool antes de llamar a `services/`), nunca depende de que el modelo decida preguntar por su cuenta.

### VII. Testing y Cobertura
1. Pirámide de pruebas obligatoria: unitarias (mayoría) → integración → API/E2E (minoría).
2. Tests unitarios de `services/` inyectan un repositorio falso (que cumple el mismo contrato que el real) como parámetro — está PROHIBIDO usar `unittest.mock` para esto, porque el diseño con DIP ya lo hace innecesario.
3. Cobertura mínima exigida:
   - 100% de las reglas de negocio explícitas de `spec.md` cubiertas por al menos un test unitario cada una (sala inválida, horario invertido, solapamiento, cancelación de reserva ajena) — cobertura de *reglas*, no solo de líneas.
   - Cobertura de líneas de `services/` ≥ 90%.
   - Cobertura de líneas del conjunto `services/ + repositories/ + routers/ + utils/` ≥ 70%, medida con `pytest --cov=app --cov-report=term-missing`. Este umbral NO exige cubrir el arranque de la app (`main.py`: lifespan, montaje ASGI de MCP), el servidor MCP en sí (`mcp/server.py`, `mcp/auth.py`) ni `logging_config.py` — son infraestructura de arranque, no lógica de negocio, y su exclusión se declara explícitamente en `[tool.coverage.run] omit` de `pyproject.toml`, nunca como una omisión silenciosa.
4. Tests de integración corren contra una base de datos real (SQLite en memoria como mínimo), nunca contra el repositorio falso.
5. Tests de API usan `app.dependency_overrides` de FastAPI para sustituir `get_db`, `get_reservas_repo` y `get_current_user` — nunca levantan un servidor real ni golpean la base de datos de desarrollo.
6. Toda tool de MCP tiene al menos dos tests: un caso exitoso y un caso de error de negocio, verificados directamente o vía MCP Inspector.
7. Ninguna tarea de `tasks.md` se considera terminada sin su test correspondiente en verde.

## Governance

1. **Autoridad y Prioridad**: Esta constitución tiene prioridad sobre cualquier decisión técnica tomada durante la especificación, diseño o implementación. Si es necesario desviarse de un artículo, la desviación debe justificarse y documentarse explícitamente (comentario en el código y advertencia en el resumen de la tarea correspondiente), nunca decidirse en silencio.
2. **Procedimiento de Enmienda**: Toda modificación o adición de principios debe tramitarse como una enmienda formal a este archivo, registrando el cambio en el reporte de sincronización e incrementando la versión conforme a SemVer.
3. **Política de Versionado**:
   - **MAJOR**: Eliminación o redefinición incompatible de principios arquitectónicos o de gobernanza.
   - **MINOR**: Incorporación de un nuevo principio o ampliación material de las guías no negociables.
   - **PATCH**: Correcciones ortográficas, clarificaciones de redacción o refinamientos no semánticos.
4. **Criterios de Verificación y Cumplimiento**: Todo pull request, tarea o módulo implementado debe verificar el cumplimiento estricto de estos artículos. Las suites de tests y umbrales de cobertura estipulados en el Artículo VII actúan como compuertas de calidad innegociables.

**Version**: 1.0.0 | **Ratified**: 2026-09-22 | **Last Amended**: 2026-09-22
