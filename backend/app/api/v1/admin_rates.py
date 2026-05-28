from __future__ import annotations

from datetime import date, datetime, timezone
from typing import List

import httpx
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.security import get_current_admin
from app.models.exchange_rate import ExchangeRate
from app.schemas.exchange_rate import ExchangeRateCreate, ExchangeRateRead

router = APIRouter(
    prefix="/admin/exchange-rates",
    tags=["admin exchange rates"],
    dependencies=[Depends(get_current_admin)],
)


@router.get("", response_model=List[ExchangeRateRead], summary="List exchange rates")
async def list_rates(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(ExchangeRate).order_by(
            ExchangeRate.from_currency,
            ExchangeRate.effective_date.desc(),
        )
    )
    return result.scalars().all()


@router.post(
    "",
    response_model=ExchangeRateRead,
    status_code=201,
    summary="Add an exchange rate",
)
async def create_rate(body: ExchangeRateCreate, db: AsyncSession = Depends(get_db)):
    rate = ExchangeRate(**body.model_dump())
    db.add(rate)
    await db.flush()
    await db.refresh(rate)
    return rate


@router.post(
    "/refresh",
    response_model=List[ExchangeRateRead],
    summary="Auto-fetch latest USD/XOF and USD/EUR rates from open.er-api.com",
)
async def refresh_rates(db: AsyncSession = Depends(get_db)):
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(settings.EXCHANGE_RATE_API)
            resp.raise_for_status()
            data = resp.json()
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Impossible de récupérer les taux: {exc}",
        )

    rates_data = data.get("rates", {})
    today = date.today()
    created: List[ExchangeRate] = []

    pairs = [
        ("USD", "XOF"),
        ("USD", "EUR"),
        ("XOF", "USD"),
        ("EUR", "USD"),
    ]
    for from_cur, to_cur in pairs:
        if from_cur == "USD":
            rate_value = rates_data.get(to_cur)
        else:
            # Compute cross rate from USD base
            from_rate = rates_data.get(from_cur)
            to_rate = rates_data.get(to_cur)
            if from_rate and to_rate:
                rate_value = to_rate / from_rate
            else:
                rate_value = None

        if rate_value is None:
            continue

        er = ExchangeRate(
            from_currency=from_cur,
            to_currency=to_cur,
            rate=rate_value,
            source="open.er-api.com",
            effective_date=today,
        )
        db.add(er)
        created.append(er)

    await db.flush()
    for er in created:
        await db.refresh(er)
    return created
