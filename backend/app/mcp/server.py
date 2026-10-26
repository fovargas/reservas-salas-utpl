from mcp.server.auth.settings import AuthSettings
from mcp.server.fastmcp import FastMCP

from app.config import settings
from app.mcp.auth import JWTTokenVerifier
from app.mcp.tools import reservas

mcp = FastMCP(
    "reservas-utpl-server",
    streamable_http_path="/",
    token_verifier=JWTTokenVerifier(),
    auth=AuthSettings(
        issuer_url=settings.mcp_issuer_url,
        resource_server_url=settings.mcp_resource_url,
        required_scopes=["reservas"],
        # Simplificación consciente: el JWT de este proyecto no trae el
        # claim de audiencia (resource) -- ver Artículo VI.4 y la nota
        # equivalente de "Gastos" (Sesión 8, Paso 6).
        validate_token_resource=False,
    ),
)
reservas.register(mcp)

if __name__ == "__main__":
    mcp.run()
