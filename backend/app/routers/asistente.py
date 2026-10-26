from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_cliente_ia, get_current_user, get_reservas_repo
from app.models.usuario import Usuario
from app.schemas.asistente import PreguntaAsistente, RespuestaAsistente
from app.services import asistente as asistente_service

router = APIRouter(prefix="/asistente", tags=["asistente"])


@router.post("/", response_model=RespuestaAsistente)
def preguntar(
    datos: PreguntaAsistente,
    db: Session = Depends(get_db),
    usuario_actual: Usuario = Depends(get_current_user),
    repo=Depends(get_reservas_repo),
    cliente_ia=Depends(get_cliente_ia),
):
    return asistente_service.responder(db, usuario_actual.id, datos.pregunta, cliente_ia, repo=repo)
