from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_admin
from app.models.admin_user import AdminUser
from app.models.country import Country
from app.schemas.country import CountryCreate, CountryRead, CountryUpdate

router = APIRouter(
    prefix="/admin/countries",
    tags=["admin countries"],
    dependencies=[Depends(get_current_admin)],
)


@router.get("", response_model=List[CountryRead], summary="List all countries")
async def list_countries(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Country).order_by(Country.name_fr))
    return result.scalars().all()


@router.post("", response_model=CountryRead, status_code=status.HTTP_201_CREATED)
async def create_country(body: CountryCreate, db: AsyncSession = Depends(get_db)):
    existing = await db.get(Country, body.code.upper())
    if existing:
        raise HTTPException(status_code=400, detail="Code pays déjà utilisé")
    country = Country(**body.model_dump())
    country.code = body.code.upper()
    db.add(country)
    await db.flush()
    await db.refresh(country)
    return country


@router.get("/{code}", response_model=CountryRead)
async def get_country(code: str, db: AsyncSession = Depends(get_db)):
    country = await db.get(Country, code.upper())
    if not country:
        raise HTTPException(status_code=404, detail="Pays introuvable")
    return country


@router.patch("/{code}", response_model=CountryRead)
async def update_country(
    code: str, body: CountryUpdate, db: AsyncSession = Depends(get_db)
):
    country = await db.get(Country, code.upper())
    if not country:
        raise HTTPException(status_code=404, detail="Pays introuvable")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(country, field, value)
    await db.flush()
    await db.refresh(country)
    return country


@router.delete("/{code}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_country(code: str, db: AsyncSession = Depends(get_db)):
    country = await db.get(Country, code.upper())
    if not country:
        raise HTTPException(status_code=404, detail="Pays introuvable")
    await db.delete(country)
