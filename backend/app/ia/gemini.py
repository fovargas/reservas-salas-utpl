import httpx

URL_BASE = "https://generativelanguage.googleapis.com/v1beta/models"


class ErrorIA(Exception):
    pass


class ClienteGemini:
    """Cliente mínimo de la API de Gemini. La clave vive solo en el .env del
    backend; la app móvil nunca la conoce."""

    def __init__(self, api_key: str, modelo: str, timeout: float = 25.0):
        self._api_key = api_key
        self._modelo = modelo
        self._timeout = timeout

    def generar_json(self, instrucciones: str, mensaje: str) -> str:
        cuerpo = {
            "systemInstruction": {"parts": [{"text": instrucciones}]},
            "contents": [{"role": "user", "parts": [{"text": mensaje}]}],
            "generationConfig": {"responseMimeType": "application/json", "temperature": 0.3},
        }
        try:
            respuesta = httpx.post(
                f"{URL_BASE}/{self._modelo}:generateContent",
                headers={"x-goog-api-key": self._api_key},
                json=cuerpo,
                timeout=self._timeout,
            )
        except httpx.HTTPError as e:
            raise ErrorIA(f"No se pudo contactar a Gemini: {type(e).__name__}") from e
        if respuesta.status_code != 200:
            raise ErrorIA(f"Gemini respondió {respuesta.status_code}")
        try:
            return respuesta.json()["candidates"][0]["content"]["parts"][0]["text"]
        except (KeyError, IndexError, ValueError) as e:
            raise ErrorIA("Respuesta de Gemini sin texto") from e
