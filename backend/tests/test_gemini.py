import httpx

from app.ia import gemini
from app.ia.gemini import ClienteGemini


class RespuestaFalsa:
    def __init__(self, codigo, datos=None):
        self.status_code = codigo
        self._datos = datos

    def json(self):
        return self._datos


def test_si_el_primer_modelo_falla_usa_el_siguiente(monkeypatch):
    llamados = []

    def post_falso(url, **kwargs):
        llamados.append(url)
        if "modelo-saturado" in url:
            return RespuestaFalsa(503)
        partes = [{"text": "pensando...", "thought": True}, {"text": '{"ok": true}'}]
        return RespuestaFalsa(200, {"candidates": [{"content": {"parts": partes}}]})

    monkeypatch.setattr(gemini.httpx, "post", post_falso)

    texto = ClienteGemini("clave-de-prueba", "modelo-saturado, modelo-bueno").generar_json("x", "y")

    assert texto == '{"ok": true}'
    assert len(llamados) == 2


def test_si_todos_fallan_lanza_error_ia(monkeypatch):
    def post_falso(url, **kwargs):
        raise httpx.ReadTimeout("lento")

    monkeypatch.setattr(gemini.httpx, "post", post_falso)

    try:
        ClienteGemini("clave-de-prueba", "a,b").generar_json("x", "y")
        assert False, "debía fallar"
    except gemini.ErrorIA:
        pass
