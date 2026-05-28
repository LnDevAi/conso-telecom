from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.security import get_current_admin
from app.models.ai_model import AiModel
from app.models.ai_provider import AiProvider
from app.schemas.ai_model import AiModelCreate, AiModelRead, AiModelUpdate
from app.schemas.ai_provider import (
    AiProviderCreate,
    AiProviderRead,
    AiProviderReadWithModels,
    AiProviderUpdate,
)

router = APIRouter(
    prefix="/admin/ai",
    tags=["admin AI"],
    dependencies=[Depends(get_current_admin)],
)


# ── AI Providers ───────────────────────────────────────────────────────────────

@router.get("/providers", response_model=List[AiProviderReadWithModels])
async def list_providers(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(AiProvider)
        .options(selectinload(AiProvider.models))
        .order_by(AiProvider.name)
    )
    return result.scalars().all()


@router.post(
    "/providers",
    response_model=AiProviderRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_provider(body: AiProviderCreate, db: AsyncSession = Depends(get_db)):
    existing = await db.get(AiProvider, body.id)
    if existing:
        raise HTTPException(status_code=400, detail="ID fournisseur déjà utilisé")
    provider = AiProvider(**body.model_dump())
    db.add(provider)
    await db.flush()
    await db.refresh(provider)
    return provider


@router.get("/providers/{provider_id}", response_model=AiProviderReadWithModels)
async def get_provider(provider_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(AiProvider)
        .where(AiProvider.id == provider_id)
        .options(selectinload(AiProvider.models))
    )
    provider = result.scalar_one_or_none()
    if not provider:
        raise HTTPException(status_code=404, detail="Fournisseur introuvable")
    return provider


@router.patch("/providers/{provider_id}", response_model=AiProviderRead)
async def update_provider(
    provider_id: str, body: AiProviderUpdate, db: AsyncSession = Depends(get_db)
):
    provider = await db.get(AiProvider, provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Fournisseur introuvable")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(provider, field, value)
    await db.flush()
    await db.refresh(provider)
    return provider


@router.delete("/providers/{provider_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_provider(provider_id: str, db: AsyncSession = Depends(get_db)):
    provider = await db.get(AiProvider, provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Fournisseur introuvable")
    await db.delete(provider)


# ── AI Models (nested under provider) ─────────────────────────────────────────

@router.get("/providers/{provider_id}/models", response_model=List[AiModelRead])
async def list_models(provider_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(AiModel)
        .where(AiModel.provider_id == provider_id)
        .order_by(AiModel.name)
    )
    return result.scalars().all()


@router.post(
    "/providers/{provider_id}/models",
    response_model=AiModelRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_model(
    provider_id: str, body: AiModelCreate, db: AsyncSession = Depends(get_db)
):
    existing = await db.get(AiModel, body.id)
    if existing:
        raise HTTPException(status_code=400, detail="ID modèle déjà utilisé")
    model = AiModel(**{**body.model_dump(), "provider_id": provider_id})
    db.add(model)
    await db.flush()
    await db.refresh(model)
    return model


@router.patch("/providers/{provider_id}/models/{model_id}", response_model=AiModelRead)
async def update_model(
    provider_id: str,
    model_id: str,
    body: AiModelUpdate,
    db: AsyncSession = Depends(get_db),
):
    model = await db.get(AiModel, model_id)
    if not model or model.provider_id != provider_id:
        raise HTTPException(status_code=404, detail="Modèle introuvable")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(model, field, value)
    await db.flush()
    await db.refresh(model)
    return model


@router.delete(
    "/providers/{provider_id}/models/{model_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_model(
    provider_id: str, model_id: str, db: AsyncSession = Depends(get_db)
):
    model = await db.get(AiModel, model_id)
    if not model or model.provider_id != provider_id:
        raise HTTPException(status_code=404, detail="Modèle introuvable")
    await db.delete(model)
