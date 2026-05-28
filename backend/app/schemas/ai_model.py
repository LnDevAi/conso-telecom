from __future__ import annotations

from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, Field


class AiModelBase(BaseModel):
    id: str = Field(..., min_length=1, max_length=128, description="Slug, e.g. 'claude-opus-4-7'")
    provider_id: str = Field(..., min_length=1, max_length=64)
    name: str = Field(..., min_length=1, max_length=255)
    input_price_per_mtok_usd: float = Field(..., ge=0, description="USD per million tokens")
    output_price_per_mtok_usd: float = Field(..., ge=0, description="USD per million tokens")
    context_window: Optional[int] = Field(None, ge=1)
    valid_from: Optional[date] = None
    valid_until: Optional[date] = None
    is_active: bool = True


class AiModelCreate(AiModelBase):
    pass


class AiModelUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    input_price_per_mtok_usd: Optional[float] = Field(None, ge=0)
    output_price_per_mtok_usd: Optional[float] = Field(None, ge=0)
    context_window: Optional[int] = Field(None, ge=1)
    valid_from: Optional[date] = None
    valid_until: Optional[date] = None
    is_active: Optional[bool] = None


class AiModelRead(AiModelBase):
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
