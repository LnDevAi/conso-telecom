from __future__ import annotations

from datetime import datetime, timezone
from typing import List, TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.operator import Operator


class Country(Base):
    __tablename__ = "countries"

    code: Mapped[str] = mapped_column(String(3), primary_key=True)  # e.g. "BF"
    name_fr: Mapped[str] = mapped_column(String(128), nullable=False)
    name_en: Mapped[str] = mapped_column(String(128), nullable=False)
    default_currency: Mapped[str] = mapped_column(String(8), nullable=False, default="XOF")
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    # Relationships
    operators: Mapped[List["Operator"]] = relationship(
        "Operator", back_populates="country", cascade="all, delete-orphan"
    )
