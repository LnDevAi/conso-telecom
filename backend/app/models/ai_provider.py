from __future__ import annotations

from datetime import datetime
from typing import List, TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.ai_model import AiModel


class AiProvider(Base):
    __tablename__ = "ai_providers"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)  # slug, e.g. "anthropic"
    name: Mapped[str] = mapped_column(String(128), nullable=False)
    website: Mapped[str | None] = mapped_column(Text, nullable=True)
    usage_api_endpoint: Mapped[str | None] = mapped_column(Text, nullable=True)
    usage_api_doc_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    # Relationships
    models: Mapped[List["AiModel"]] = relationship(
        "AiModel", back_populates="provider", cascade="all, delete-orphan"
    )
