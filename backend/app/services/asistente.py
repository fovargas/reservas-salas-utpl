import json
import logging
import re
from datetime import date, timedelta

from app.ia.gemini import ErrorIA
from app.repositories import reservas as reservas_repository
from app.utils.salas import CATALOGO_SALAS, SALAS_POR_ID

logger = logging.getLogger(__name__)

DIAS_DE_CONTEXTO = 7

INSTRUCCIONES = """Eres el asistente de reservas de salas de la UTPL (campus Loja).
Responde en español neutro, en máximo 120 palabras.
Usa SOLO los datos del contexto: no inventes salas, horarios ni reservas.
No puedes crear ni cancelar reservas; si la persona quiere reservar, sugiere
la sala y dile que use el botón «Reservar» en el detalle de la sala.
Devuelve exclusivamente un JSON con esta forma:
{"respuesta": "<texto>", "salas_sugeridas": ["<id de sala del catálogo>", ...]}"""

PALABRAS_TIPO = {
    "laboratorio": ["laboratorio", "computador", "práctica", "practica"],
    "auditorio": ["auditorio", "evento", "conferencia", "ceremonia", "magna"],
    "reuniones": ["reunión", "reunion", "junta", "comité", "comite"],
    "estudio": ["estudiar", "estudio", "grupal", "tarea", "lectura"],
    "aula": ["clase", "aula", "taller", "curso"],
    "multimedia": ["grabar", "grabación", "grabacion", "video", "podcast"],
}


def construir_contexto(db, usuario_id: int, hoy: date, repo=reservas_repository) -> dict:
    hasta = hoy + timedelta(days=DIAS_DE_CONTEXTO)
    reservas = repo.listar_entre_fechas(db, hoy, hasta)
    return {
        "hoy": hoy.isoformat(),
        "salas": CATALOGO_SALAS,
        # Sin identidad de otros usuarios: solo qué franjas están ocupadas.
        "ocupacion": [
            {
                "sala": r["sala"],
                "fecha": r["fecha"].isoformat(),
                "inicio": r["hora_inicio"].strftime("%H:%M"),
                "fin": r["hora_fin"].strftime("%H:%M"),
                "propia": r["usuario_id"] == usuario_id,
            }
            for r in reservas
        ],
    }


def responder(db, usuario_id: int, pregunta: str, cliente_ia, hoy: date | None = None, repo=reservas_repository) -> dict:
    contexto = construir_contexto(db, usuario_id, hoy or date.today(), repo=repo)
    if cliente_ia is not None:
        try:
            return _respuesta_ia(cliente_ia, pregunta, contexto)
        except ErrorIA as e:
            logger.warning("Asistente en modo básico por fallo de IA: %s", e)
    return _respuesta_basica(pregunta, contexto)


def _respuesta_ia(cliente_ia, pregunta: str, contexto: dict) -> dict:
    mensaje = f"Contexto:\n{json.dumps(contexto, ensure_ascii=False)}\n\nPregunta: {pregunta}"
    texto = cliente_ia.generar_json(INSTRUCCIONES, mensaje)
    try:
        datos = json.loads(texto)
        respuesta = str(datos["respuesta"]).strip()
        sugeridas = datos.get("salas_sugeridas") or []
    except (ValueError, KeyError, TypeError, AttributeError) as e:
        raise ErrorIA("La IA no devolvió el JSON esperado") from e
    if not respuesta:
        raise ErrorIA("La IA devolvió una respuesta vacía")
    # La salida de un modelo es un dato: solo se aceptan ids reales del catálogo.
    validas = [s for s in sugeridas if isinstance(s, str) and s in SALAS_POR_ID]
    return {"respuesta": respuesta, "modo": "ia", "salas_sugeridas": validas[:3]}


def _respuesta_basica(pregunta: str, contexto: dict) -> dict:
    texto = pregunta.lower()
    personas = max((int(n) for n in re.findall(r"\d+", texto)), default=0)
    tipos = {
        t for t, palabras in PALABRAS_TIPO.items() if any(re.search(rf"\b{re.escape(p)}\b", texto) for p in palabras)
    }

    ocupadas_por_sala: dict[str, int] = {}
    for franja in contexto["ocupacion"]:
        ocupadas_por_sala[franja["sala"]] = ocupadas_por_sala.get(franja["sala"], 0) + 1

    candidatas = [
        s
        for s in CATALOGO_SALAS
        if s["capacidad"] >= personas and (not tipos or s["tipo"] in tipos)
    ]
    candidatas.sort(key=lambda s: (ocupadas_por_sala.get(s["id"], 0), s["capacidad"]))
    elegidas = candidatas[:3]

    if not elegidas:
        respuesta = (
            "No encontré una sala que cumpla todo lo que pides. "
            f"La sala más grande del campus tiene {max(s['capacidad'] for s in CATALOGO_SALAS)} puestos."
        )
    else:
        lista = "; ".join(f"{s['nombre']} ({s['edificio']}, {s['capacidad']} personas)" for s in elegidas)
        cierre = "Es la que tiene" if len(elegidas) == 1 else "Son las que tienen"
        respuesta = f"Te sugiero: {lista}. {cierre} menos reservas en los próximos días."
    propias = sum(1 for f in contexto["ocupacion"] if f["propia"])
    if propias:
        respuesta += f" Tienes {propias} {'reserva' if propias == 1 else 'reservas'} en los próximos {DIAS_DE_CONTEXTO} días."
    return {
        "respuesta": respuesta,
        "modo": "basico",
        "salas_sugeridas": [s["id"] for s in elegidas],
    }
