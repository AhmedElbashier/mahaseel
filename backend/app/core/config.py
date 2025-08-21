from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import AnyHttpUrl
from typing import List

class Settings(BaseSettings):
    app_name: str = "mahaseel"
    env: str = "dev"
    api_host: str = "0.0.0.0"
    api_port: int = 8000

    database_url: str = "sqlite:///./dev.db"  # replaced on Day 3
    cors_origins: List[AnyHttpUrl] | List[str] = []

    model_config = SettingsConfigDict(env_file="backend/.env", case_sensitive=False)

    @property
    def is_dev(self) -> bool:
        return self.env.lower() == "dev"

settings = Settings()

