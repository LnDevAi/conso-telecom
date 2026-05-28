from __future__ import annotations

import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi

from app.api.v1 import health, tariffs, auth, admin_countries, admin_operators, admin_ai, admin_rates
from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.services.seed import seed_database

log = structlog.get_logger(__name__)


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        docs_url="/api/docs",
        redoc_url="/api/redoc",
        openapi_url="/api/openapi.json",
        debug=settings.DEBUG,
    )

    # ── CORS ──────────────────────────────────────────────────────────────────
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── Routers ───────────────────────────────────────────────────────────────
    app.include_router(health.router)
    app.include_router(tariffs.router, prefix="/api/v1")
    app.include_router(auth.router, prefix="/api/v1")
    app.include_router(admin_countries.router, prefix="/api/v1")
    app.include_router(admin_operators.router, prefix="/api/v1")
    app.include_router(admin_ai.router, prefix="/api/v1")
    app.include_router(admin_rates.router, prefix="/api/v1")

    # ── Startup event — run seed ───────────────────────────────────────────────
    @app.on_event("startup")
    async def startup_event() -> None:
        log.info("Starting ConsoTélécom API", version=settings.APP_VERSION)
        async with AsyncSessionLocal() as db:
            try:
                await seed_database(db)
            except Exception as exc:
                log.error("Seed failed (non-fatal)", error=str(exc))

    @app.on_event("shutdown")
    async def shutdown_event() -> None:
        log.info("Shutting down ConsoTélécom API")

    return app


app = create_app()
