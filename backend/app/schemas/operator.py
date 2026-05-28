from __future__ import annotations

import uuid
from typing import List, Optional

from pydantic import BaseModel, Field, HttpUrl

from app.schemas.tariff_plan import TariffPlanRead
from app.schemas.unit_tariff import UnitTariffRead


class OperatorBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=128)
    country_code: str = Field(..., min_length=2, max_length=3)
    ussd_balance_code: Optional[str] = Field(None, max_length=32)
    ussd_data_code: Optional[str] = Field(None, max_length=32)
    logo_url: Optional[str] = None
    is_active: bool = True


class OperatorCreate(OperatorBase):
    pass


class OperatorUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=128)
    ussd_balance_code: Optional[str] = Field(None, max_length=32)
    ussd_data_code: Optional[str] = Field(None, max_length=32)
    logo_url: Optional[str] = None
    is_active: Optional[bool] = None


class OperatorRead(OperatorBase):
    id: uuid.UUID

    model_config = {"from_attributes": True}


class OperatorReadWithTariffs(OperatorRead):
    tariff_plans: List[TariffPlanRead] = []
    unit_tariffs: List[UnitTariffRead] = []
