from __future__ import annotations

from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.models.ai_provider import AiProvider
from app.models.country import Country
from app.models.exchange_rate import ExchangeRate
from app.models.operator import Operator
from app.schemas.ai_provider import AiProviderReadWithModels
from app.schemas.country import CountryRead
from app.schemas.exchange_rate import ExchangeRateRead
from app.schemas.operator import OperatorReadWithTariffs

router = APIRouter(prefix="/tariffs", tags=["tariffs (public)"])


@router.get("/countries", response_model=List[CountryRead], summary="All active countries")
async def list_countries(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Country).where(Country.is_active == True).order_by(Country.name_fr)
    )
    return result.scalars().all()


@router.get(
    "/operators/{country_code}",
    response_model=List[OperatorReadWithTariffs],
    summary="Operators for a country with plans and unit tariffs",
)
async def list_operators_by_country(
    country_code: str,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Operator)
        .where(
            Operator.country_code == country_code.upper(),
            Operator.is_active == True,
        )
        .options(
            selectinload(Operator.tariff_plans),
            selectinload(Operator.unit_tariffs),
        )
        .order_by(Operator.name)
    )
    return result.scalars().all()


@router.get(
    "/ai-providers",
    response_model=List[AiProviderReadWithModels],
    summary="AI providers with models and pricing",
)
async def list_ai_providers(db: AsyncSession = Depends(get_db)):
    from app.models.ai_model import AiModel

    result = await db.execute(
        select(AiProvider)
        .where(AiProvider.is_active == True)
        .options(selectinload(AiProvider.models))
        .order_by(AiProvider.name)
    )
    return result.scalars().all()


@router.get(
    "/exchange-rates",
    response_model=List[ExchangeRateRead],
    summary="Latest exchange rates",
)
async def list_exchange_rates(db: AsyncSession = Depends(get_db)):
    # Return the most recent rate per currency pair
    result = await db.execute(
        select(ExchangeRate).order_by(
            ExchangeRate.from_currency,
            ExchangeRate.to_currency,
            ExchangeRate.effective_date.desc(),
        )
    )
    rates = result.scalars().all()

    # De-duplicate: keep the latest per pair
    seen: dict = {}
    unique: list = []
    for rate in rates:
        key = (rate.from_currency, rate.to_currency)
        if key not in seen:
            seen[key] = True
            unique.append(rate)
    return unique


@router.get(
    "/updates",
    summary="Delta sync — changes since a given timestamp",
)
async def get_updates(
    since: Optional[datetime] = Query(
        None,
        description="ISO-8601 UTC timestamp. Returns all data if omitted.",
    ),
    db: AsyncSession = Depends(get_db),
):
    from app.models.tariff_plan import TariffPlan
    from app.models.unit_tariff import UnitTariff
    from app.models.ai_model import AiModel
    from app.schemas.tariff_plan import TariffPlanRead
    from app.schemas.unit_tariff import UnitTariffRead
    from app.schemas.ai_model import AiModelRead

    timestamp = since or datetime(2000, 1, 1, tzinfo=timezone.utc)

    # Plans updated since timestamp
    plans_result = await db.execute(
        select(TariffPlan).where(TariffPlan.updated_at >= timestamp)
    )
    plans = plans_result.scalars().all()

    # Unit tariffs
    unit_result = await db.execute(
        select(UnitTariff).where(UnitTariff.updated_at >= timestamp)
    )
    units = unit_result.scalars().all()

    # AI models
    models_result = await db.execute(
        select(AiModel).where(AiModel.updated_at >= timestamp)
    )
    ai_models = models_result.scalars().all()

    # Exchange rates (use created_at)
    rates_result = await db.execute(
        select(ExchangeRate).where(ExchangeRate.created_at >= timestamp)
    )
    rates = rates_result.scalars().all()

    return {
        "server_time": datetime.now(timezone.utc).isoformat(),
        "since": timestamp.isoformat(),
        "tariff_plans": [TariffPlanRead.model_validate(p) for p in plans],
        "unit_tariffs": [UnitTariffRead.model_validate(u) for u in units],
        "ai_models": [AiModelRead.model_validate(m) for m in ai_models],
        "exchange_rates": [ExchangeRateRead.model_validate(r) for r in rates],
    }
