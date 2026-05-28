from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field

from app.schemas.ai_model import AiModelRead


class AiProviderBase(BaseModel):
    id: str = Field(..., min_length=1, max_length=64, description="Slug identifier, e.g. 'anthropic'")
    name: str = Field(..., min_length=1, max_length=128)
    website: Optional[str] = None
    usage_api_endpoint: Optional[str] = None
    usage_api_doc_url: Optional[str] = None
    is_active: bool = True


class AiProviderCreate(AiProviderBase):
    pass


class AiProviderUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=128)
    website: Optional[str] = None
    usage_api_endpoint: Optional[str] = None
    usage_api_doc_url: Optional[str] = None
    is_active: Optional[bool] = None


class AiProviderRead(AiProviderBase):
    created_at: datetime

    model_config = {"from_attributes": True}


class AiProviderReadWithModels(AiProviderRead):
    models: List[AiModelRead] = []
