from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.models.tariff_plan import PlanType


class TariffPlanBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    plan_type: PlanType
    data_limit_mb: Optional[int] = Field(None, ge=0)
    voice_limit_minutes: Optional[int] = Field(None, ge=0)
    sms_limit: Optional[int] = Field(None, ge=0)
    price: float = Field(..., ge=0)
    currency: str = Field("XOF", min_length=3, max_length=8)
    validity_days: int = Field(30, ge=1)
    valid_from: Optional[date] = None
    valid_until: Optional[date] = None
    is_active: bool = True


class TariffPlanCreate(TariffPlanBase):
    operator_id: uuid.UUID


class TariffPlanUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    plan_type: Optional[PlanType] = None
    data_limit_mb: Optional[int] = Field(None, ge=0)
    voice_limit_minutes: Optional[int] = Field(None, ge=0)
    sms_limit: Optional[int] = Field(None, ge=0)
    price: Optional[float] = Field(None, ge=0)
    currency: Optional[str] = Field(None, min_length=3, max_length=8)
    validity_days: Optional[int] = Field(None, ge=1)
    valid_from: Optional[date] = None
    valid_until: Optional[date] = None
    is_active: Optional[bool] = None


class TariffPlanRead(TariffPlanBase):
    id: uuid.UUID
    operator_id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
