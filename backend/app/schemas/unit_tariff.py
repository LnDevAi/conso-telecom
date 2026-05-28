from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.models.unit_tariff import ResourceType


class UnitTariffBase(BaseModel):
    resource_type: ResourceType
    price: float = Field(..., ge=0)
    currency: str = Field("XOF", min_length=3, max_length=8)
    valid_from: Optional[date] = None
    valid_until: Optional[date] = None
    is_active: bool = True


class UnitTariffCreate(UnitTariffBase):
    operator_id: uuid.UUID


class UnitTariffUpdate(BaseModel):
    resource_type: Optional[ResourceType] = None
    price: Optional[float] = Field(None, ge=0)
    currency: Optional[str] = Field(None, min_length=3, max_length=8)
    valid_from: Optional[date] = None
    valid_until: Optional[date] = None
    is_active: Optional[bool] = None


class UnitTariffRead(UnitTariffBase):
    id: uuid.UUID
    operator_id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
