from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user, get_reservas_repo
from app.models.usuario import Usuario
from app.schemas.sala import FranjaOcupada, SalaResponse
from app.services import salas as salas_service
from app.services.salas import SalaNoEncontradaError

router = APIRouter(prefix="/salas", tags=["salas"])


@router.get("/", response_model=list[SalaResponse])
def listar():
    return salas_service.listar_salas()


@router.get("/{sala_id}", response_model=SalaResponse)
def obtener(sala_id: str):
    try:
        return salas_service.obtener_sala(sala_id)
    except SalaNoEncontradaError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/{sala_id}/ocupacion", response_model=list[FranjaOcupada])
def ocupacion(
    sala_id: str,
    fecha: date,
    db: Session = Depends(get_db),
    usuario_actual: Usuario = Depends(get_current_user),
    repo=Depends(get_reservas_repo),
):
    try:
        return salas_service.ocupacion(db, sala_id, fecha, usuario_actual.id, repo=repo)
    except SalaNoEncontradaError as e:
        raise HTTPException(status_code=404, detail=str(e))
