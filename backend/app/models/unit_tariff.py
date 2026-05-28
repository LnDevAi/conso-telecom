from __future__ import annotations

import uuid
import enum
from datetime import date, datetime
from typing import Optional, TYPE_CHECKING

from sqlalchemy import Boolean, Date, DateTime, Enum, ForeignKey, Numeric, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.operator import Operator


class ResourceType(str, enum.Enum):
    DATA_MB = "DATA_MB"
    CALL_ONNET_MIN = "CALL_ONNET_MIN"
    CALL_OFFNET_MIN = "CALL_OFFNET_MIN"
    CALL_INTL_MIN = "CALL_INTL_MIN"
    SMS_ONNET = "SMS_ONNET"
    SMS_OFFNET = "SMS_OFFNET"


class UnitTariff(Base):
    __tablename__ = "unit_tariffs"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    operator_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("operators.id", ondelete="CASCADE"),
        nullable=False,
    )
    resource_type: Mapped[ResourceType] = mapped_column(
        Enum(ResourceType, name="resource_type_enum"), nullable=False
    )
    price: Mapped[float] = mapped_column(Numeric(14, 6), nullable=False)
    currency: Mapped[str] = mapped_column(String(8), nullable=False, default="XOF")
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
    operator: Mapped["Operator"] = relationship("Operator", back_populates="unit_tariffs")
