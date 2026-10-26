# AGENTS.md — reglas del proyecto Reservas de Salas UTPL

Archivo de contexto para agentes de código (Claude Code, Codex, Antigravity). Corto y concreto.

## Qué es el proyecto

App Flutter (Android) para reservar espacios del campus UTPL (salas de reuniones, laboratorios, auditorios, aulas) y su backend FastAPI. La app usa GetX para el estado, `dio` contra el backend con JWT, `flutter_secure_storage` para el token y Hive para favoritas y copias sin conexión. El asistente de IA vive en el backend (`POST /asistente/`, Gemini); la app nunca conoce la clave.

## Dónde está cada cosa

- `app/lib/screens/` y `app/lib/widgets/` — interfaz. Las pantallas solo hablan con controladores.
- `app/lib/controllers/` — estado compartido (GetX).
- `app/lib/services/` — HTTP (`ApiClient`, `ReservasApi`) y token seguro.
- `app/lib/repositories/almacen_local.dart` — Hive.
- `app/test/` — pruebas con un servidor falso (`test/apoyo.dart`); no necesitan backend.
- `backend/app/` — routers → services → repositories (FastAPI + SQLAlchemy). Catálogo de salas en `backend/app/utils/salas.py`.
- `backend/tests/` — pytest con repositorios falsos.

## Cómo verificar (siempre, antes de dar un cambio por terminado)

```bash
cd app && flutter analyze && flutter test
cd backend && uv run ruff check . && uv run pytest -q
```

Todo debe terminar sin errores. Si algo falla, corrige el código; no desactives el análisis ni borres pruebas.

## Convenciones

- Ninguna pantalla llama HTTP ni Hive: pantalla → controlador → servicio o repositorio.
- Cada pantalla con datos cubre cargando, vacío y error.
- Textos visibles en español neutro.
- En el backend, las reglas de negocio van en `services/` y reciben el repositorio por parámetro.
- Una prueba por cada comportamiento nuevo.

## Prohibido

- Escribir claves, tokens o contraseñas en el código, en los registros o en este archivo. No leer ni modificar `backend/.env`.
- Agregar dependencias sin avisar antes y explicar por qué hacen falta.
- Ejecutar `git push` o crear etiquetas: eso lo hace la persona después de revisar.

## Reglas del proyecto

- Los nombres de clases, funciones y variables van en español, igual que en el resto del código.
- Antes de crear un widget nuevo, revisa si ya existe uno parecido en `app/lib/widgets/`.
- La salida del modelo de IA es un dato: el backend valida los ids de sala antes de devolverlos.
