import logging

import httpx

URL_BASE = "https://generativelanguage.googleapis.com/v1beta/models"

# Códigos con los que vale la pena probar el siguiente modelo de la lista:
# retirado (404), cuota (429) o saturado (503).
CODIGOS_PARA_REINTENTAR = {404, 429, 500, 503}

logger = logging.getLogger(__name__)


class ErrorIA(Exception):
    pass


class ClienteGemini:
    """Cliente mínimo de la API de Gemini. La clave vive solo en el .env del
    backend; la app móvil nunca la conoce. `modelos` es una lista separada por
    comas: si uno falla, se prueba el siguiente."""

    def __init__(self, api_key: str, modelos: str, timeout: float = 12.0):
        self._api_key = api_key
        self._modelos = [m.strip() for m in modelos.split(",") if m.strip()]
        self._timeout = timeout

    def generar_json(self, instrucciones: str, mensaje: str) -> str:
        cuerpo = {
            "systemInstruction": {"parts": [{"text": instrucciones}]},
            "contents": [{"role": "user", "parts": [{"text": mensaje}]}],
            "generationConfig": {"responseMimeType": "application/json", "temperature": 0.3},
        }
        ultimo_error = ErrorIA("No hay modelos de Gemini configurados")
        for modelo in self._modelos:
            try:
                return self._llamar(modelo, cuerpo)
            except ErrorIA as e:
                logger.warning("Gemini %s falló: %s", modelo, e)
                ultimo_error = e
        raise ultimo_error

    def _llamar(self, modelo: str, cuerpo: dict) -> str:
        try:
            respuesta = httpx.post(
                f"{URL_BASE}/{modelo}:generateContent",
                headers={"x-goog-api-key": self._api_key},
                json=cuerpo,
                timeout=self._timeout,
            )
        except httpx.HTTPError as e:
            raise ErrorIA(f"No se pudo contactar a Gemini: {type(e).__name__}") from e
        if respuesta.status_code != 200:
            raise ErrorIA(f"Gemini respondió {respuesta.status_code}")
        try:
            partes = respuesta.json()["candidates"][0]["content"]["parts"]
        except (KeyError, IndexError, ValueError) as e:
            raise ErrorIA("Respuesta de Gemini sin texto") from e
        # Los modelos con razonamiento devuelven partes «thought»: no son la respuesta.
        texto = "".join(p.get("text", "") for p in partes if not p.get("thought"))
        if not texto:
            raise ErrorIA("Respuesta de Gemini sin texto")
        return texto
