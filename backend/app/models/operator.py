from __future__ import annotations

import uuid
from typing import List, TYPE_CHECKING

from sqlalchemy import Boolean, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.country import Country
    from app.models.tariff_plan import TariffPlan
    from app.models.unit_tariff import UnitTariff


class Operator(Base):
    __tablename__ = "operators"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(128), nullable=False)
    country_code: Mapped[str] = mapped_column(
        String(3), ForeignKey("countries.code", ondelete="CASCADE"), nullable=False
    )
    ussd_balance_code: Mapped[str | None] = mapped_column(String(32), nullable=True)
    ussd_data_code: Mapped[str | None] = mapped_column(String(32), nullable=True)
    logo_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    # Relationships
    country: Mapped["Country"] = relationship("Country", back_populates="operators")
    tariff_plans: Mapped[List["TariffPlan"]] = relationship(
        "TariffPlan", back_populates="operator", cascade="all, delete-orphan"
    )
    unit_tariffs: Mapped[List["UnitTariff"]] = relationship(
        "UnitTariff", back_populates="operator", cascade="all, delete-orphan"
    )
