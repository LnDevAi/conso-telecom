from fastapi import APIRouter
from app.core.config import settings

router = APIRouter(tags=["health"])


@router.get("/api/health", summary="Health check")
async def health_check():
    return {"status": "ok", "version": settings.APP_VERSION}
