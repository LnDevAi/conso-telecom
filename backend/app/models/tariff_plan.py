from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Optional, TYPE_CHECKING

from sqlalchemy import Boolean, Date, DateTime, Enum, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.operator import Operator


class PlanType(str, enum.Enum):
    DATA = "DATA"
    VOICE = "VOICE"
    SMS = "SMS"
    COMBO = "COMBO"


class TariffPlan(Base):
    __tablename__ = "tariff_plans"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    operator_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("operators.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    plan_type: Mapped[PlanType] = mapped_column(
        Enum(PlanType, name="plan_type_enum"), nullable=False
    )
    data_limit_mb: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    voice_limit_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    sms_limit: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    price: Mapped[float] = mapped_column(Numeric(14, 4), nullable=False)
    currency: Mapped[str] = mapped_column(String(8), nullable=False, default="XOF")
    validity_days: Mapped[int] = mapped_column(Integer, nullable=False, default=30)
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
    operator: Mapped["Operator"] = relationship("Operator", back_populates="tariff_plans")
