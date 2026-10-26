from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.reserva import ReservaCreate, ReservaResponse
from app.services import reservas as reservas_service
from app.services.reservas import (
    SalaInvalidaError,
    HorarioInvalidoError,
    SolapamientoError,
    ReservaNoEncontradaError,
    ReservaAjenaError,
)
from app.dependencies import get_current_user, get_reservas_repo
from app.models.usuario import Usuario

router = APIRouter(prefix="/reservas", tags=["reservas"])


@router.post("/", response_model=ReservaResponse, status_code=201)
def crear(
    datos: ReservaCreate,
    db: Session = Depends(get_db),
    usuario_actual: Usuario = Depends(get_current_user),
    repo=Depends(get_reservas_repo),
):
    try:
        return reservas_service.crear_reserva(
            db,
            usuario_actual.id,
            datos.sala,
            datos.fecha,
            datos.hora_inicio,
            datos.hora_fin,
            datos.motivo,
            repo=repo,
        )
    except (SalaInvalidaError, HorarioInvalidoError, SolapamientoError) as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/", response_model=list[ReservaResponse])
def listar(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    usuario_actual: Usuario = Depends(get_current_user),
    repo=Depends(get_reservas_repo),
):
    return reservas_service.listar_reservas(db, usuario_actual.id, skip, limit, repo=repo)


@router.delete("/{reserva_id}", status_code=status.HTTP_204_NO_CONTENT)
def cancelar(
    reserva_id: int,
    db: Session = Depends(get_db),
    usuario_actual: Usuario = Depends(get_current_user),
    repo=Depends(get_reservas_repo),
):
    try:
        reservas_service.cancelar_reserva(db, usuario_actual.id, reserva_id, repo=repo)
    except ReservaNoEncontradaError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ReservaAjenaError as e:
        raise HTTPException(status_code=403, detail=str(e))
