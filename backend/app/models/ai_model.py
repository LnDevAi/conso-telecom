from __future__ import annotations

from datetime import date, datetime
from typing import Optional, TYPE_CHECKING

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.ai_provider import AiProvider


class AiModel(Base):
    __tablename__ = "ai_models"

    id: Mapped[str] = mapped_column(String(128), primary_key=True)  # slug, e.g. "claude-opus-4-7"
    provider_id: Mapped[str] = mapped_column(
        String(64), ForeignKey("ai_providers.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    input_price_per_mtok_usd: Mapped[float] = mapped_column(Numeric(12, 6), nullable=False)
    output_price_per_mtok_usd: Mapped[float] = mapped_column(Numeric(12, 6), nullable=False)
    context_window: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    valid_from: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    valid_until: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    # Relationships
    provider: Mapped["AiProvider"] = relationship("AiProvider", back_populates="models")
