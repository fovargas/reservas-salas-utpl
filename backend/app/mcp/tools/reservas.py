from datetime import date, time

from mcp.server.auth.middleware.auth_context import get_access_token
from mcp.server.fastmcp import FastMCP

from app.config import settings
from app.database import SessionLocal
from app.repositories import usuarios as usuarios_repository
from app.security import hash_password
from app.services import reservas as reservas_service


def _obtener_o_crear_usuario_demo(db):
    """
    Simplificación intencional, acotada a stdio (Artículo VI.4): ese
    transporte no tiene forma de portar un Bearer token, así que usa un
    usuario de demostración fijo. Sobre HTTP (streamable-http), el Bearer
    token (mismo JWT de REST) sí identifica al usuario real -- ver
    JWTTokenVerifier (app/mcp/auth.py) y _resolver_usuario_actual abajo.

    El email/password del usuario demo vienen de Settings (.env), no
    quemados en el código.
    """
    usuario = usuarios_repository.obtener_por_email(db, settings.mcp_demo_email)
    if usuario is None:
        usuario = usuarios_repository.guardar(
            db, settings.mcp_demo_email, hash_password(settings.mcp_demo_password)
        )
    return usuario


def _resolver_usuario_actual(db):
    access_token = get_access_token()
    if access_token is None:
        # Sin token solo puede ser stdio: sobre HTTP, RequireAuthMiddleware
        # ya respondió 401 antes de llegar aquí.
        return _obtener_o_crear_usuario_demo(db)

    usuario = None
    if access_token.subject:
        usuario = usuarios_repository.obtener_por_email(db, access_token.subject)
    if usuario is None:
        # Hay token pero no corresponde a nadie (usuario borrado): se
        # rechaza. NUNCA se cae al usuario demo cuando hay un token de por medio.
        raise ValueError("El token no corresponde a ningún usuario registrado")
    return usuario


def register(mcp: FastMCP) -> None:
    """Registra los tools de reservas sobre la instancia de FastMCP que le pasa server.py."""

    @mcp.tool()
    def crear_reserva(
        sala: str, fecha: date, hora_inicio: time, hora_fin: time, motivo: str = ""
    ) -> dict:
        """Crea una reserva de una sala del campus UTPL para una fecha y horario dados,
        validando que la sala exista en el catálogo y que no se solape con otra reserva
        ya existente para esa misma sala y horario. Usar cuando el usuario quiera
        reservar un espacio (sala de reuniones, auditorio, laboratorio, etc.)."""
        db = SessionLocal()
        try:
            usuario = _resolver_usuario_actual(db)
            return reservas_service.crear_reserva(
                db, usuario.id, sala, fecha, hora_inicio, hora_fin, motivo or None
            )
        except (
            reservas_service.SalaInvalidaError,
            reservas_service.HorarioInvalidoError,
            reservas_service.SolapamientoError,
            ValueError,
        ) as e:
            # Manejo de errores en tools: se devuelve texto claro, no una excepción sin control
            return {"error": str(e)}
        finally:
            db.close()

    @mcp.tool()
    def listar_reservas(skip: int = 0, limit: int = 20) -> list[dict]:
        """Lista las reservas de salas registradas del usuario autenticado, paginadas.
        Usar cuando pregunten por sus reservas o quieran un resumen de sus próximos
        horarios reservados en el campus."""
        db = SessionLocal()
        try:
            usuario = _resolver_usuario_actual(db)
            return reservas_service.listar_reservas(db, usuario.id, skip, limit)
        finally:
            db.close()

    @mcp.tool()
    def cancelar_reserva(reserva_id: int, confirmar: bool = False) -> dict:
        """Cancela una reserva existente del usuario autenticado, identificada por su id.
        Es una acción destructiva: exige que 'confirmar' llegue en True explícitamente
        (la confirmación la exige este servidor, no el criterio del modelo) -- si no,
        devuelve un error pidiendo confirmación explícita antes de ejecutar el borrado."""
        if not confirmar:
            return {
                "error": (
                    "Acción destructiva sin confirmar. Vuelve a llamar a esta tool "
                    "con confirmar=true para cancelar la reserva."
                )
            }

        db = SessionLocal()
        try:
            usuario = _resolver_usuario_actual(db)
            reservas_service.cancelar_reserva(db, usuario.id, reserva_id)
            return {"cancelada": True, "reserva_id": reserva_id}
        except (
            reservas_service.ReservaNoEncontradaError,
            reservas_service.ReservaAjenaError,
            ValueError,
        ) as e:
            return {"error": str(e)}
        finally:
            db.close()
