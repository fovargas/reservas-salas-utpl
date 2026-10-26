from datetime import date, time

from sqlalchemy.orm import Session

from app.models.reserva import Reserva
from app.utils.validadores import se_solapan


def _a_dict(reserva: Reserva) -> dict:
    return {
        "id": reserva.id,
        "sala": reserva.sala,
        "fecha": reserva.fecha,
        "hora_inicio": reserva.hora_inicio,
        "hora_fin": reserva.hora_fin,
        "motivo": reserva.motivo,
        "usuario_id": reserva.usuario_id,
    }


def guardar(
    db: Session,
    usuario_id: int,
    sala: str,
    fecha: date,
    hora_inicio: time,
    hora_fin: time,
    motivo: str | None,
) -> dict:
    reserva = Reserva(
        usuario_id=usuario_id,
        sala=sala,
        fecha=fecha,
        hora_inicio=hora_inicio,
        hora_fin=hora_fin,
        motivo=motivo,
    )
    db.add(reserva)
    db.commit()
    db.refresh(reserva)
    return _a_dict(reserva)


def listar(db: Session, usuario_id: int, skip: int = 0, limit: int = 20) -> list[dict]:
    reservas = (
        db.query(Reserva)
        .filter(Reserva.usuario_id == usuario_id)
        .order_by(Reserva.fecha, Reserva.hora_inicio)
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [_a_dict(r) for r in reservas]


def obtener_por_id(db: Session, reserva_id: int) -> dict | None:
    reserva = db.query(Reserva).filter(Reserva.id == reserva_id).first()
    return _a_dict(reserva) if reserva else None


def existe_solapamiento(db: Session, sala: str, fecha: date, hora_inicio: time, hora_fin: time) -> bool:
    """Consulta las reservas de la MISMA sala y fecha (sin filtrar por
    usuario_id -- es una regla de disponibilidad del espacio físico, no de
    privacidad de datos, Artículo III.3) y compara en memoria con
    se_solapan(), portable entre SQLite y Postgres sin operadores de rango
    específicos del motor."""
    candidatas = db.query(Reserva).filter(Reserva.sala == sala, Reserva.fecha == fecha).all()
    return any(se_solapan(hora_inicio, hora_fin, r.hora_inicio, r.hora_fin) for r in candidatas)


def eliminar(db: Session, reserva_id: int) -> None:
    reserva = db.query(Reserva).filter(Reserva.id == reserva_id).first()
    if reserva is not None:
        db.delete(reserva)
        db.commit()
