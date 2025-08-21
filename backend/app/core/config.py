from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import AnyHttpUrl
from typing import List
from datetime import timedelta

class Settings(BaseSettings):
    app_name: str = "mahaseel"
    env: str = "dev"
    api_host: str = "0.0.0.0"
    api_port: int = 8000

    jwt_secret: str = "CHANGE_ME_DEV_ONLY"
    jwt_algorithm: str = "HS256"
    jwt_access_minutes: int = 60

    database_url: str = "postgresql+psycopg://mahaseel:mahaseel@localhost:5432/mahaseel"
    cors_origins: List[AnyHttpUrl] | List[str] = []

    model_config = SettingsConfigDict(env_file="backend/.env", case_sensitive=False)

    @property
    def is_dev(self) -> bool:
        return self.env.lower() == "dev"


    # helper
    @property
    def access_expires(self) -> timedelta:
        return timedelta(minutes=self.jwt_access_minutes)


settings = Settings()

