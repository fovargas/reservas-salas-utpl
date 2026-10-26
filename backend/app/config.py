from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    secret_key: str
    database_url: str = "sqlite:///./reservas.db"
    access_token_expire_minutes: int = 30
    log_level: str = "INFO"
    mcp_demo_email: str = "demo@utpl.edu.ec"
    mcp_demo_password: str = "demo1234"
    mcp_issuer_url: str = "http://127.0.0.1:8000"
    mcp_resource_url: str = "http://127.0.0.1:8000/mcp"


settings = Settings()
