"""Test configuration and fixtures for ConsoTélécom backend."""

from __future__ import annotations

import asyncio
from typing import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.database import get_db
from app.core.security import get_password_hash
from app.main import app
from app.models.base import Base
from app.models.admin_user import AdminUser
from app.models.country import Country
from app.models.operator import Operator
from app.models.ai_provider import AiProvider
from app.models.ai_model import AiModel
from app.models.tariff_plan import TariffPlan, PlanType
from app.models.unit_tariff import UnitTariff, ResourceType
from app.models.exchange_rate import ExchangeRate

TEST_DATABASE_URL = "sqlite+aiosqlite:///./test.db"

test_engine = create_async_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
)

TestingSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session", autouse=True)
async def setup_db():
    """Create all tables once per test session."""
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await test_engine.dispose()


@pytest_asyncio.fixture
async def db() -> AsyncGenerator[AsyncSession, None]:
    async with TestingSessionLocal() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(db: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """HTTP client with overridden DB dependency."""

    async def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def seeded_db(db: AsyncSession) -> AsyncSession:
    """Seed minimal test data."""
    # Country
    country = Country(code="BF", name_fr="Burkina Faso", name_en="Burkina Faso", default_currency="XOF")
    db.add(country)

    # Operator
    import uuid
    op = Operator(id=uuid.uuid4(), name="Orange BF", country_code="BF",
                  ussd_balance_code="#124#", ussd_data_code="*150*1#")
    db.add(op)
    await db.flush()

    # Tariff plan
    plan = TariffPlan(
        operator_id=op.id,
        name="Forfait Test 1 Go",
        plan_type=PlanType.DATA,
        data_limit_mb=1024,
        price=1000,
        currency="XOF",
        validity_days=7,
    )
    db.add(plan)

    # Unit tariff
    ut = UnitTariff(operator_id=op.id, resource_type=ResourceType.DATA_MB, price=5.0, currency="XOF")
    db.add(ut)

    # AI provider + model
    provider = AiProvider(id="anthropic", name="Anthropic", website="https://anthropic.com")
    db.add(provider)
    model = AiModel(
        id="claude-sonnet-4-6",
        provider_id="anthropic",
        name="Claude Sonnet 4.6",
        input_price_per_mtok_usd=3.0,
        output_price_per_mtok_usd=15.0,
        context_window=200000,
    )
    db.add(model)

    # Exchange rate
    from datetime import date
    er = ExchangeRate(from_currency="USD", to_currency="XOF", rate=600.0, source="test", effective_date=date.today())
    db.add(er)

    # Admin user
    admin = AdminUser(email="admin@test.com", hashed_password=get_password_hash("test1234"), is_active=True)
    db.add(admin)

    await db.commit()
    return db
