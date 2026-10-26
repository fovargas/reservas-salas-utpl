from datetime import time

from app.utils.salas import SALAS_POR_ID

# OCP: agregar una sala nueva del campus = agregarla en utils/salas.py.
SALAS_VALIDAS = set(SALAS_POR_ID)


def sala_valida(sala: str) -> bool:
    return sala in SALAS_VALIDAS


def horario_valido(hora_inicio: time, hora_fin: time) -> bool:
    return hora_fin > hora_inicio


def se_solapan(inicio_a: time, fin_a: time, inicio_b: time, fin_b: time) -> bool:
    """Intersección estricta de intervalos: [08:00,10:00) y [10:00,11:00)
    NO se solapan -- el fin de una reserva puede coincidir con el inicio de
    la siguiente (ver spec.md, sección Clarifications)."""
    return inicio_a < fin_b and fin_a > inicio_b
