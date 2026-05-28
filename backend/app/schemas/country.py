from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class CountryBase(BaseModel):
    code: str = Field(..., min_length=2, max_length=3, description="ISO 3166-1 alpha-2/3 code")
    name_fr: str = Field(..., min_length=1, max_length=128)
    name_en: str = Field(..., min_length=1, max_length=128)
    default_currency: str = Field("XOF", min_length=3, max_length=8)
    is_active: bool = True


class CountryCreate(CountryBase):
    pass


class CountryUpdate(BaseModel):
    name_fr: Optional[str] = Field(None, min_length=1, max_length=128)
    name_en: Optional[str] = Field(None, min_length=1, max_length=128)
    default_currency: Optional[str] = Field(None, min_length=3, max_length=8)
    is_active: Optional[bool] = None


class CountryRead(CountryBase):
    created_at: datetime

    model_config = {"from_attributes": True}
