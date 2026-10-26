# Feature Specification: Reservas de Salas y Espacios Compartidos UTPL

**Feature Branch**: `001-reservas-salas-utpl`

**Created**: 2026-09-22

**Status**: Ready for Planning

**Input**: User description: "Sistema de reservas de salas y espacios compartidos del campus UTPL con arquitectura en capas, API REST y herramientas MCP bajo autenticación OAuth2 y JWT"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reserva de Espacio en el Campus (Priority: P1)

Como docente, investigador o estudiante de la UTPL, quiero reservar una sala o espacio compartido del campus en una fecha y horario específicos, para asegurar la disponibilidad del espacio físico sin conflictos con otros miembros de la comunidad universitaria.

**Why this priority**: Es el flujo central y la razón de ser del sistema (reserva sin solapamiento de espacios físicos del campus).

**Independent Test**: Puede probarse de forma integral creando una reserva con datos válidos y comprobando que el espacio queda registrado y que cualquier intento posterior de reserva sobre la misma sala y horario genera un conflicto de solapamiento.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado y una sala disponible en el catálogo (`auditorio_campus`), **When** solicita una reserva para una fecha válida (`YYYY-MM-DD`) con `hora_inicio < hora_fin`, **Then** el sistema crea la reserva con código `201`, asignándola a su identidad y persistiendo los datos.
2. **Given** una reserva existente para una sala en el horario `09:00 - 11:00`, **When** cualquier usuario intenta reservar la misma sala en la misma fecha para `10:00 - 12:00`, **Then** el sistema rechaza la solicitud con error `400 SolapamientoError`.
3. **Given** una sala no perteneciente al catálogo universitario (ej. `cancha_sintetica`), **When** se solicita una reserva, **Then** el sistema rechaza la solicitud con error `400 SalaInvalidaError`.
4. **Given** un horario donde `hora_fin <= hora_inicio` (ej. `14:00` a `13:00`), **When** se solicita la reserva, **Then** el sistema rechaza la operación con error `400 HorarioInvalidoError`.

---

### User Story 2 - Consulta y Gestión de Reservas Propias (Priority: P2)

Como miembro de la comunidad UTPL con reservas activas, quiero consultar el historial de mis reservas y cancelar aquellas que ya no necesite, para liberar el espacio a otros colegas y mantener el control sobre mis apartados.

**Why this priority**: Permite la auto-gestión del ciclo de vida de las reservas y asegura la liberación de espacios compartidos.

**Independent Test**: Puede probarse listando las reservas del usuario autenticado comprobando que no se exponen reservas de terceros, y cancelando una reserva propia verificando que se elimina correctamente y rechaza cancelaciones de reservas ajenas.

**Acceptance Scenarios**:

1. **Given** un usuario autenticado con reservas previas, **When** solicita la lista de sus reservas (con paginación `skip` y `limit`), **Then** el sistema retorna `200 OK` únicamente con las reservas asociadas a su `usuario_id`.
2. **Given** una reserva existente perteneciente al usuario autenticado, **When** solicita la cancelación mediante `DELETE /reservas/{id}`, **Then** el sistema la elimina y responde con `204 No Content`.
3. **Given** una reserva perteneciente a otro usuario, **When** el usuario autenticado intenta cancelarla indicando su identificador, **Then** el sistema deniega la acción con código `403 Forbidden` (`ReservaAjenaError`).
4. **Given** un identificador de reserva inexistente, **When** el usuario solicita su cancelación, **Then** el sistema responde con `404 Not Found`.

---

### User Story 3 - Interacción mediante Asistente MCP (Priority: P2)

Como usuario que interactúa mediante agentes de IA o clientes MCP (Claude Desktop, agentes IDE), quiero consultar disponibilidad, reservar salas y cancelarlas mediante herramientas de lenguaje natural, manteniendo las mismas reglas de seguridad y confirmación.

**Why this priority**: Habilita la interfaz agentic del proyecto integrador garantizando paridad total con la API REST y protección contra acciones destructivas no deseadas.

**Independent Test**: Invocación directa de tools MCP (`crear_reserva`, `listar_reservas`, `cancelar_reserva`), verificando propagación de identidad y bloqueo de cancelación si `confirmar` no es `True`.

**Acceptance Scenarios**:

1. **Given** una sesión MCP con autenticación válida, **When** el agente invoca `crear_reserva` con sala, fecha y horas válidas, **Then** el sistema delega al mismo servicio de reservas y retorna la reserva creada.
2. **Given** una solicitud de `cancelar_reserva` vía MCP, **When** el parámetro `confirmar` es `False` o se omite, **Then** la herramienta devuelve un error estructurado exigiendo confirmación explícita sin alterar la persistencia.

---

### User Story 4 - Registro y Autenticación Segura (Priority: P3)

Como nuevo docente o estudiante, quiero registrar mi cuenta con correo institucional y obtener credenciales de acceso JWT seguras, para autenticarme tanto en la API REST como en la sesión de MCP.

**Why this priority**: Fundamento de seguridad que soporta la atribución de reservas y el control de acceso.

**Independent Test**: Registro de un nuevo correo con contraseña de longitud adecuada (mínimo 8 caracteres), intento de duplicación rechazado con 400, y canje de credenciales por token JWT con 200.

**Acceptance Scenarios**:

1. **Given** un email no registrado y una contraseña válida (mínimo 8 caracteres), **When** se envía a `POST /usuarios/`, **Then** el sistema retorna `201 Created` con los datos del usuario (sin exponer el hash de contraseña).
2. **Given** un email ya registrado, **When** se intenta crear de nuevo, **Then** el sistema responde con `400 Bad Request` indicando correo duplicado.
3. **Given** credenciales correctas en `POST /usuarios/token`, **When** se solicita el token, **Then** el sistema responde con `200 OK` y un token Bearer JWT con tiempo de expiración finito.

---

### Edge Cases

- **Reservas contiguas en el límite temporal**: Una reserva que culmina exactamente a las `10:00` y otra que inicia a las `10:00` para la misma sala y fecha **no** se consideran solapadas. El solapamiento se define como intersección estricta de intervalos abiertos a derecha: `[hora_inicio, hora_fin)`.
- **Múltiples salas a la misma hora**: Un usuario puede reservar dos salas distintas en el mismo horario. La restricción de solapamiento aplica exclusivamente al espacio físico (`sala`), no a la agenda de la persona.
- **Formato y zona horaria**: Todas las fechas se interpretan en formato ISO 8601 `YYYY-MM-DD` y las horas en `HH:MM` o `HH:MM:SS` correspondientes a la zona horaria del campus UTPL (`America/Guayaquil`, UTC-5).
- **Control de límites en paginación**: Peticiones con `limit` menor a 1 o mayor a 100 devuelven error de validación `422 Unprocessable Entity` para evitar sobrecarga del servidor.
- **Manejo de identidad en transporte stdio**: Si el servidor MCP opera por entrada/salida estándar sin capacidad de cabeceras HTTP, se utiliza un usuario demo explícitamente configurado en las variables de entorno (`MCP_DEMO_EMAIL`), documentado en código como excepción consciente.
- **Normalización de motivo opcional**: El campo `motivo` acepta cadenas de hasta 255 caracteres o valor nulo (`None`). Si se recibe cadena vacía `""`, se normaliza a `None` en la capa de servicio.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mantener un catálogo cerrado e inmutable en tiempo de ejecución con las 5 salas reservables del campus: `sala_reuniones_biblioteca`, `auditorio_campus`, `laboratorio_redes`, `sala_posgrados`, `aula_magna` mediante la constante `SALAS_VALIDAS` en `app/utils/validadores.py`.
- **FR-002**: El sistema DEBE rechazar con `SalaInvalidaError` (HTTP `400`) cualquier solicitud de reserva sobre una sala que no pertenezca estrictamente al catálogo `SALAS_VALIDAS`.
- **FR-003**: El sistema DEBE validar que `hora_fin` sea estrictamente posterior a `hora_inicio`, rechazando casos contrarios o iguales con `HorarioInvalidoError` (HTTP `400`).
- **FR-004**: El sistema DEBE validar que no exista solapamiento temporal sobre la misma sala y fecha con reservas existentes, evaluando la condición estricta: `nueva.hora_inicio < existente.hora_fin AND nueva.hora_fin > existente.hora_inicio`, lanzando `SolapamientoError` (HTTP `400`) ante cruces.
- **FR-005**: El sistema DEBE permitir el registro de usuarios con email único y contraseña (mínimo 8 caracteres), almacenando la contraseña únicamente mediante hash seguro con `passlib[bcrypt]` (`bcrypt < 4.1`) y retornando código HTTP `201`.
- **FR-006**: El sistema DEBE emitir tokens de acceso JWT (firmados con algoritmo HS256 y expiración finita) contra el endpoint `POST /usuarios/token` ante credenciales válidas, o responder `401 Unauthorized` si son inválidas.
- **FR-007**: El sistema DEBE exigir autenticación JWT válida para todos los endpoints de reservas (`POST /reservas/`, `GET /reservas/`, `DELETE /reservas/{id}`), derivando la identidad del solicitante exclusivamente del token verificado.
- **FR-008**: El sistema DEBE permitir la creación de reservas con campos `sala`, `fecha`, `hora_inicio`, `hora_fin` y `motivo` opcional (máximo 255 caracteres), retornando HTTP `201` con la representación pública de la reserva creada.
- **FR-009**: El sistema DEBE proveer un endpoint de consulta paginada (`GET /reservas/`) con parámetros `skip` (default 0, ge=0) y `limit` (default 20, ge=1, le=100), filtrando los resultados de forma estricta para devolver únicamente las reservas del usuario autenticado.
- **FR-010**: El sistema DEBE permitir la cancelación de reservas (`DELETE /reservas/{id}`), verificando primero si la reserva existe (o devolver `404 Not Found`) y si pertenece al usuario solicitante; si pertenece a otro usuario, DEBE rechazar la solicitud con `403 Forbidden` (`ReservaAjenaError`).
- **FR-011**: El sistema DEBE exponer herramientas MCP equivalentes (`crear_reserva`, `listar_reservas`, `cancelar_reserva`) que deleguen directamente a la capa de servicios (`app/services/reservas.py`), sin duplicar reglas de negocio.
- **FR-012**: La herramienta MCP `cancelar_reserva` DEBE exigir el parámetro booleano `confirmar` con valor `True` verificado por el servidor antes de invocar la capa de servicio; si `confirmar` es `False`, debe abortar y requerir confirmación explícita.
- **FR-013**: El sistema DEBE cumplir el contrato interno no negociable de firmas y excepciones establecido en `app/services/reservas.py` (con inyección de repositorio por parámetro `repo=reservas_repository` bajo DIP) y `app/repositories/reservas.py` (devolviendo diccionarios o tipos desacoplados del ORM).

### Contrato de la API (REST)

| Método | Ruta | Auth | Request | Éxito | Errores esperados |
|--------|------|------|---------|-------|-------------------|
| POST | `/usuarios/` | No | email, password | 201 Usuario | 400 email duplicado, 422 validación |
| POST | `/usuarios/token` | No | username, password (form) | 200 token JWT | 401 credenciales inválidas |
| POST | `/reservas/` | Sí | sala, fecha, hora_inicio, hora_fin, motivo? | 201 Reserva | 400 sala inválida, 400 horas inválidas, 400 horario solapado, 401, 422 |
| GET | `/reservas/` | Sí | query: skip (default 0), limit (default 20, max 100) | 200 lista | 401, 422 (skip/limit inválidos) |
| DELETE | `/reservas/{id}` | Sí | — | 204 | 401, 403 no es dueño, 404 |

### Contrato Equivalente por MCP

- **Tool `crear_reserva(sala, fecha, hora_inicio, hora_fin, motivo=None)`**: Mismas reglas que `POST /reservas/`, operando sobre el usuario autenticado de la sesión MCP.
- **Tool `listar_reservas(skip=0, limit=20)`**: Mismo comportamiento que `GET /reservas/`.
- **Tool `cancelar_reserva(reserva_id, confirmar: bool)`**: Exige `confirmar=True` verificado en servidor antes de llamar a servicios, y verifica propiedad de la reserva.

### Contrato de Compatibilidad Interno (Firmas No Negociables)

- `app/services/reservas.py`:
  - Clases de excepción: `SalaInvalidaError`, `HorarioInvalidoError`, `SolapamientoError`, `ReservaNoEncontradaError`, `ReservaAjenaError`.
  - `crear_reserva(db, usuario_id, sala, fecha, hora_inicio, hora_fin, motivo=None, repo=reservas_repository) -> dict`
  - `listar_reservas(db, usuario_id, skip=0, limit=20, repo=reservas_repository) -> list[dict]`
  - `cancelar_reserva(db, usuario_id, reserva_id, repo=reservas_repository) -> None`
- `app/repositories/reservas.py`:
  - `guardar(db, usuario_id, sala, fecha, hora_inicio, hora_fin, motivo) -> dict`
  - `listar(db, usuario_id, skip=0, limit=20) -> list[dict]`
  - `obtener_por_id(db, reserva_id) -> dict | None`
  - `existe_solapamiento(db, sala, fecha, hora_inicio, hora_fin) -> bool`
  - `eliminar(db, reserva_id) -> None`
- `app/repositories/usuarios.py`:
  - `obtener_por_email(db, email) -> Usuario | None`
  - `guardar(db, email, hashed_password) -> Usuario`
- `app.database.get_db`, `app.dependencies.get_current_user`, `app.dependencies.get_reservas_repo`, `app.models.usuario.Usuario(id=, email=, hashed_password=)`.
- `tests/__init__.py`: existente para permitir imports en tests.

### Key Entities

- **Usuario**: Representa un miembro del campus con acceso al sistema. Atributos: `id` (entero/identificador primario), `email` (cadena única validada con formato de correo), `hashed_password` (hash de contraseña seguro, nunca devuelto al cliente), `created_at` (marca temporal).
- **Reserva**: Representa la asignación exclusiva de un espacio físico en un bloque temporal. Atributos: `id` (identificador primario), `sala` (cadena del catálogo de salas válidas), `fecha` (fecha del evento `YYYY-MM-DD`), `hora_inicio` (hora de inicio `HH:MM`), `hora_fin` (hora de fin `HH:MM`), `motivo` (texto descriptivo opcional hasta 255 caracteres), `usuario_id` (clave foránea que referencia al Usuario creador).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% de las reglas de negocio explícitas (catálogo cerrado, horarios coherentes, prevención de solapamientos, cancelación restrictiva de reservas ajenas) están cubiertas por pruebas unitarias automatizadas con resultado exitoso.
- **SC-002**: Cobertura de pruebas de código superior o igual al 90% en la capa de servicios (`app/services/`) y superior o igual al 70% en el conjunto del núcleo del proyecto (`services + repositories + routers + utils`).
- **SC-003**: Cero exposiciones de excepciones internas, trazas o detalles de persistencia hacia los clientes en respuestas de error (máscara de error interno `500` con `{"detail": "Error interno del servidor"}`).
- **SC-004**: Paridad funcional del 100% entre las operaciones de creación, listado y cancelación expuestas por la API REST y las herramientas del servidor MCP.
- **SC-005**: 100% de cumplimiento en las reglas de estilo y linting del proyecto verificadas por `ruff`.

## Assumptions

- Se asume un conjunto cerrado de 5 salas reservables definidas institucionalmente por el campus UTPL para el alcance de esta fase.
- La zona horaria operativa de todas las reservas corresponde a la hora oficial de Ecuador (`America/Guayaquil` / UTC-5).
- El transporte principal para producción y pruebas integradas es HTTP con autenticación de cabecera Bearer JWT (`streamable-http`). Para herramientas locales en stdio, se cuenta con la contingencia documentada del usuario de demostración de `.env`.
- La persistencia utiliza SQLite para entornos locales y de pruebas, garantizando portabilidad hacia PostgreSQL sin alteraciones en los servicios ni routers.
