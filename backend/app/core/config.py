from __future__ import annotations

import json
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── Database ──────────────────────────────────────────────────────────────
    DATABASE_URL: str = (
        "postgresql+asyncpg://consotelecom:consotelecom@db:5432/consotelecom"
    )
    DATABASE_SYNC_URL: str = (
        "postgresql://consotelecom:consotelecom@db:5432/consotelecom"
    )

    # ── Security ──────────────────────────────────────────────────────────────
    SECRET_KEY: str = "CHANGE_ME_USE_A_REAL_64_HEX_SECRET_KEY_IN_PRODUCTION"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 8  # 8 hours

    # ── CORS ──────────────────────────────────────────────────────────────────
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "https://admin.consotelecom.app",
    ]

    # ── App ───────────────────────────────────────────────────────────────────
    DEBUG: bool = False
    APP_VERSION: str = "2.0.0"
    APP_NAME: str = "ConsoTélécom API"

    # ── Seed admin ────────────────────────────────────────────────────────────
    ADMIN_EMAIL: str = "admin@edefence.tech"
    ADMIN_PASSWORD: str = "CHANGE_ME_STRONG_PASSWORD"

    # ── External ──────────────────────────────────────────────────────────────
    EXCHANGE_RATE_API: str = "https://open.er-api.com/v6/latest/USD"

    def allowed_origins_list(self) -> List[str]:
        return self.ALLOWED_ORIGINS


settings = Settings()
