from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field


class ExchangeRateBase(BaseModel):
    from_currency: str = Field(..., min_length=3, max_length=8)
    to_currency: str = Field(..., min_length=3, max_length=8)
    rate: float = Field(..., gt=0)
    source: str = Field("manual", max_length=128)
    effective_date: date


class ExchangeRateCreate(ExchangeRateBase):
    pass


class ExchangeRateRead(ExchangeRateBase):
    id: uuid.UUID
    created_at: datetime

    model_config = {"from_attributes": True}
