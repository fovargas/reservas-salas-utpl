# Lista de verificación — Reservas de Salas UTPL

La rúbrica del Proyecto Final convertida en comprobaciones, con dónde está la evidencia en este repositorio.

## 1. Persistencia remota o colaborativa (20 %)

- [x] Crear, ver y cancelar reservas desde la app; quedan en el backend. *Evidencia:* `backend/app/routers/reservas.py`, pantalla **Mis reservas**.
- [x] Sin sesión se rechaza con 401. *Evidencia:* `backend/tests/test_api_reservas.py::test_crear_reserva_sin_token_devuelve_401`.
- [x] Colaborativo: la ocupación de una sala muestra las reservas de otros usuarios (sin identificarlos). *Evidencia:* `GET /salas/{id}/ocupacion`, `backend/tests/test_api_salas.py`.

## 2. Autenticación (15 %)

- [x] Registro, inicio y cierre de sesión. *Evidencia:* `app/lib/controllers/auth_controller.dart`.
- [x] Token en `flutter_secure_storage`; la sesión sobrevive al reinicio (`GET /usuarios/me`). *Evidencia:* prueba «con un token guardado abre la sesión sin pedir credenciales».

## 3. Datos reales (15 %)

- [x] Catálogo de 20 salas servido por el backend (`GET /salas/`), no escrito en la app. *Evidencia:* `backend/app/utils/salas.py`.

## 4. Persistencia local (10 %)

- [x] Favoritas en Hive, sobreviven al cierre completo. Copia del catálogo y de las reservas para ver sin conexión. *Evidencia:* `app/lib/repositories/almacen_local.dart`.

## 5. Estado con GetX (10 %)

- [x] Estado compartido en `AuthController`, `SalasController`, `ReservasController`, `AsistenteController` y `NavegacionController`. `setState` solo para estado local de formularios.

## 6. IA sin secretos (10 %)

- [x] La app llama a `POST /asistente/` de su backend; la clave de Gemini vive en `backend/.env`.
- [x] Auditoría limpia (ver README → Seguridad); `backend/.env` ignorado y nunca subido.

## 7. Manejo de errores (10 %)

- [x] Carga, vacío y error en Salas, Mis reservas, Favoritas, disponibilidad y Asistente.
- [x] Mensajes distintos para 400, 401, 403, 404, 422, 5xx, tiempo agotado y sin conexión. *Evidencia:* `app/test/api_exception_test.dart`.
- [x] Errores no controlados capturados por `ReporteErrores.instalar()`.

## 8. Arquitectura (5 %)

- [x] Ninguna pantalla llama HTTP ni Hive: pantalla → controlador → `ReservasApi` / `AlmacenLocal`.

## 9. Documentación y entrega (5 %)

- [x] README con ejecución, direcciones por entorno, arquitectura, decisión técnica, seguridad y créditos.
- [x] Historial de commits real.
- [ ] Release `v1.0.0` con el APK generado por Actions, probado en un emulador limpio.
- [ ] Enlace del repositorio subido a Moodle.
