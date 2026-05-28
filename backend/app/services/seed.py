"""Seed the database with real initial data for ConsoTélécom v2.0."""

from __future__ import annotations

import uuid
from datetime import date

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import get_password_hash
from app.models.admin_user import AdminUser
from app.models.ai_model import AiModel
from app.models.ai_provider import AiProvider
from app.models.country import Country
from app.models.exchange_rate import ExchangeRate
from app.models.operator import Operator
from app.models.tariff_plan import PlanType, TariffPlan
from app.models.unit_tariff import ResourceType, UnitTariff

log = structlog.get_logger(__name__)


async def seed_database(db: AsyncSession) -> None:
    """Idempotent seed — skips if data already exists."""

    # ── Admin user ─────────────────────────────────────────────────────────────
    existing_admin = await db.execute(
        select(AdminUser).where(AdminUser.email == settings.ADMIN_EMAIL)
    )
    if not existing_admin.scalar_one_or_none():
        admin = AdminUser(
            email=settings.ADMIN_EMAIL,
            hashed_password=get_password_hash(settings.ADMIN_PASSWORD),
            is_active=True,
        )
        db.add(admin)
        log.info("Admin user created", email=settings.ADMIN_EMAIL)

    # ── Country: Burkina Faso ──────────────────────────────────────────────────
    existing_bf = await db.get(Country, "BF")
    if not existing_bf:
        bf = Country(
            code="BF",
            name_fr="Burkina Faso",
            name_en="Burkina Faso",
            default_currency="XOF",
            is_active=True,
        )
        db.add(bf)
        await db.flush()
        log.info("Country seeded", code="BF")

        # ── Operators ─────────────────────────────────────────────────────────

        # Orange BF
        orange_id = uuid.uuid4()
        orange = Operator(
            id=orange_id,
            name="Orange Burkina Faso",
            country_code="BF",
            ussd_balance_code="#124#",
            ussd_data_code="*150*1#",
            logo_url="https://assets.consotelecom.app/logos/orange-bf.png",
            is_active=True,
        )
        db.add(orange)

        # Moov Africa BF
        moov_id = uuid.uuid4()
        moov = Operator(
            id=moov_id,
            name="Moov Africa Burkina Faso",
            country_code="BF",
            ussd_balance_code="#111#",
            ussd_data_code="*111#",
            logo_url="https://assets.consotelecom.app/logos/moov-bf.png",
            is_active=True,
        )
        db.add(moov)

        # Telecel Faso
        telecel_id = uuid.uuid4()
        telecel = Operator(
            id=telecel_id,
            name="Telecel Faso",
            country_code="BF",
            ussd_balance_code="#123#",
            ussd_data_code=None,
            logo_url="https://assets.consotelecom.app/logos/telecel-bf.png",
            is_active=True,
        )
        db.add(telecel)
        await db.flush()
        log.info("Operators seeded", count=3)

        # ── Orange Tariff Plans ────────────────────────────────────────────────
        orange_plans = [
            TariffPlan(
                operator_id=orange_id,
                name="Pass 100 Mo / 24h",
                plan_type=PlanType.DATA,
                data_limit_mb=100,
                price=200,
                currency="XOF",
                validity_days=1,
                is_active=True,
            ),
            TariffPlan(
                operator_id=orange_id,
                name="Forfait 1 Go / 7 jours",
                plan_type=PlanType.DATA,
                data_limit_mb=1024,
                price=1000,
                currency="XOF",
                validity_days=7,
                is_active=True,
            ),
            TariffPlan(
                operator_id=orange_id,
                name="Forfait 5 Go / 30 jours",
                plan_type=PlanType.DATA,
                data_limit_mb=5120,
                price=4000,
                currency="XOF",
                validity_days=30,
                is_active=True,
            ),
            TariffPlan(
                operator_id=orange_id,
                name="Pass Voix 30 min / 24h",
                plan_type=PlanType.VOICE,
                voice_limit_minutes=30,
                price=300,
                currency="XOF",
                validity_days=1,
                is_active=True,
            ),
            TariffPlan(
                operator_id=orange_id,
                name="Combo 2 Go + 60 min / 30j",
                plan_type=PlanType.COMBO,
                data_limit_mb=2048,
                voice_limit_minutes=60,
                price=3500,
                currency="XOF",
                validity_days=30,
                is_active=True,
            ),
        ]
        for p in orange_plans:
            db.add(p)

        # ── Moov Tariff Plans ──────────────────────────────────────────────────
        moov_plans = [
            TariffPlan(
                operator_id=moov_id,
                name="Pass 200 Mo / 24h",
                plan_type=PlanType.DATA,
                data_limit_mb=200,
                price=250,
                currency="XOF",
                validity_days=1,
                is_active=True,
            ),
            TariffPlan(
                operator_id=moov_id,
                name="Forfait 2 Go / 30 jours",
                plan_type=PlanType.DATA,
                data_limit_mb=2048,
                price=2500,
                currency="XOF",
                validity_days=30,
                is_active=True,
            ),
            TariffPlan(
                operator_id=moov_id,
                name="Forfait 5 Go / 30 jours",
                plan_type=PlanType.DATA,
                data_limit_mb=5120,
                price=5000,
                currency="XOF",
                validity_days=30,
                is_active=True,
            ),
            TariffPlan(
                operator_id=moov_id,
                name="Pass Voix 20 min / 24h",
                plan_type=PlanType.VOICE,
                voice_limit_minutes=20,
                price=200,
                currency="XOF",
                validity_days=1,
                is_active=True,
            ),
        ]
        for p in moov_plans:
            db.add(p)

        # ── Telecel Tariff Plans ───────────────────────────────────────────────
        telecel_plans = [
            TariffPlan(
                operator_id=telecel_id,
                name="Pass 500 Mo / 7 jours",
                plan_type=PlanType.DATA,
                data_limit_mb=500,
                price=800,
                currency="XOF",
                validity_days=7,
                is_active=True,
            ),
            TariffPlan(
                operator_id=telecel_id,
                name="Forfait 3 Go / 30 jours",
                plan_type=PlanType.DATA,
                data_limit_mb=3072,
                price=3000,
                currency="XOF",
                validity_days=30,
                is_active=True,
            ),
        ]
        for p in telecel_plans:
            db.add(p)

        # ── Unit Tariffs ───────────────────────────────────────────────────────
        today = date.today()

        # Orange unit tariffs
        orange_units = [
            UnitTariff(operator_id=orange_id, resource_type=ResourceType.DATA_MB, price=5.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=orange_id, resource_type=ResourceType.CALL_ONNET_MIN, price=10.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=orange_id, resource_type=ResourceType.CALL_OFFNET_MIN, price=20.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=orange_id, resource_type=ResourceType.CALL_INTL_MIN, price=100.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=orange_id, resource_type=ResourceType.SMS_ONNET, price=25.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=orange_id, resource_type=ResourceType.SMS_OFFNET, price=35.0, currency="XOF", is_active=True),
        ]
        for u in orange_units:
            db.add(u)

        # Moov unit tariffs
        moov_units = [
            UnitTariff(operator_id=moov_id, resource_type=ResourceType.DATA_MB, price=5.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=moov_id, resource_type=ResourceType.CALL_ONNET_MIN, price=10.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=moov_id, resource_type=ResourceType.CALL_OFFNET_MIN, price=20.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=moov_id, resource_type=ResourceType.CALL_INTL_MIN, price=120.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=moov_id, resource_type=ResourceType.SMS_ONNET, price=25.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=moov_id, resource_type=ResourceType.SMS_OFFNET, price=35.0, currency="XOF", is_active=True),
        ]
        for u in moov_units:
            db.add(u)

        # Telecel unit tariffs
        telecel_units = [
            UnitTariff(operator_id=telecel_id, resource_type=ResourceType.DATA_MB, price=4.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=telecel_id, resource_type=ResourceType.CALL_ONNET_MIN, price=10.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=telecel_id, resource_type=ResourceType.CALL_OFFNET_MIN, price=20.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=telecel_id, resource_type=ResourceType.CALL_INTL_MIN, price=150.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=telecel_id, resource_type=ResourceType.SMS_ONNET, price=25.0, currency="XOF", is_active=True),
            UnitTariff(operator_id=telecel_id, resource_type=ResourceType.SMS_OFFNET, price=35.0, currency="XOF", is_active=True),
        ]
        for u in telecel_units:
            db.add(u)

        await db.flush()
        log.info("Tariff plans and unit tariffs seeded")

    # ── AI Providers ───────────────────────────────────────────────────────────
    existing_anthropic = await db.get(AiProvider, "anthropic")
    if not existing_anthropic:
        today = date.today()

        providers_data = [
            {
                "id": "anthropic",
                "name": "Anthropic",
                "website": "https://anthropic.com",
                "usage_api_endpoint": "https://api.anthropic.com/v1/usage",
                "usage_api_doc_url": "https://docs.anthropic.com/en/api/usage",
            },
            {
                "id": "openai",
                "name": "OpenAI",
                "website": "https://openai.com",
                "usage_api_endpoint": "https://api.openai.com/v1/usage",
                "usage_api_doc_url": "https://platform.openai.com/docs/api-reference/usage",
            },
            {
                "id": "google",
                "name": "Google DeepMind",
                "website": "https://deepmind.google",
                "usage_api_endpoint": "https://generativelanguage.googleapis.com",
                "usage_api_doc_url": "https://ai.google.dev/gemini-api/docs",
            },
            {
                "id": "mistral",
                "name": "Mistral AI",
                "website": "https://mistral.ai",
                "usage_api_endpoint": "https://api.mistral.ai/v1/fim/completions",
                "usage_api_doc_url": "https://docs.mistral.ai/api/",
            },
        ]

        for pd in providers_data:
            provider = AiProvider(**pd, is_active=True)
            db.add(provider)

        await db.flush()
        log.info("AI providers seeded", count=len(providers_data))

        # ── AI Models ──────────────────────────────────────────────────────────
        models_data = [
            # Anthropic Claude
            {
                "id": "claude-opus-4-7",
                "provider_id": "anthropic",
                "name": "Claude Opus 4.7",
                "input_price_per_mtok_usd": 15.0,
                "output_price_per_mtok_usd": 75.0,
                "context_window": 200000,
            },
            {
                "id": "claude-sonnet-4-6",
                "provider_id": "anthropic",
                "name": "Claude Sonnet 4.6",
                "input_price_per_mtok_usd": 3.0,
                "output_price_per_mtok_usd": 15.0,
                "context_window": 200000,
            },
            {
                "id": "claude-haiku-4-5",
                "provider_id": "anthropic",
                "name": "Claude Haiku 4.5",
                "input_price_per_mtok_usd": 0.80,
                "output_price_per_mtok_usd": 4.0,
                "context_window": 200000,
            },
            # OpenAI
            {
                "id": "gpt-4o",
                "provider_id": "openai",
                "name": "GPT-4o",
                "input_price_per_mtok_usd": 2.50,
                "output_price_per_mtok_usd": 10.0,
                "context_window": 128000,
            },
            {
                "id": "gpt-4o-mini",
                "provider_id": "openai",
                "name": "GPT-4o Mini",
                "input_price_per_mtok_usd": 0.15,
                "output_price_per_mtok_usd": 0.60,
                "context_window": 128000,
            },
            {
                "id": "o1",
                "provider_id": "openai",
                "name": "o1",
                "input_price_per_mtok_usd": 15.0,
                "output_price_per_mtok_usd": 60.0,
                "context_window": 200000,
            },
            # Google Gemini
            {
                "id": "gemini-2-5-pro",
                "provider_id": "google",
                "name": "Gemini 2.5 Pro",
                "input_price_per_mtok_usd": 1.25,
                "output_price_per_mtok_usd": 10.0,
                "context_window": 1000000,
            },
            {
                "id": "gemini-2-0-flash",
                "provider_id": "google",
                "name": "Gemini 2.0 Flash",
                "input_price_per_mtok_usd": 0.10,
                "output_price_per_mtok_usd": 0.40,
                "context_window": 1000000,
            },
            # Mistral
            {
                "id": "mistral-large",
                "provider_id": "mistral",
                "name": "Mistral Large",
                "input_price_per_mtok_usd": 2.0,
                "output_price_per_mtok_usd": 6.0,
                "context_window": 128000,
            },
            {
                "id": "mistral-small",
                "provider_id": "mistral",
                "name": "Mistral Small",
                "input_price_per_mtok_usd": 0.10,
                "output_price_per_mtok_usd": 0.30,
                "context_window": 32000,
            },
        ]

        for md in models_data:
            model = AiModel(**md, is_active=True)
            db.add(model)

        await db.flush()
        log.info("AI models seeded", count=len(models_data))

    # ── Exchange Rates ─────────────────────────────────────────────────────────
    existing_xof = await db.execute(
        select(ExchangeRate).where(
            ExchangeRate.from_currency == "USD",
            ExchangeRate.to_currency == "XOF",
        )
    )
    if not existing_xof.scalar_one_or_none():
        today = date.today()
        rates = [
            ExchangeRate(
                from_currency="USD",
                to_currency="XOF",
                rate=600.0,
                source="seed_data",
                effective_date=today,
            ),
            ExchangeRate(
                from_currency="XOF",
                to_currency="USD",
                rate=1 / 600.0,
                source="seed_data",
                effective_date=today,
            ),
            ExchangeRate(
                from_currency="EUR",
                to_currency="XOF",
                rate=655.957,
                source="fixed_CFA_rate",
                effective_date=today,
            ),
            ExchangeRate(
                from_currency="XOF",
                to_currency="EUR",
                rate=1 / 655.957,
                source="fixed_CFA_rate",
                effective_date=today,
            ),
            ExchangeRate(
                from_currency="USD",
                to_currency="EUR",
                rate=0.92,
                source="seed_data",
                effective_date=today,
            ),
            ExchangeRate(
                from_currency="EUR",
                to_currency="USD",
                rate=1 / 0.92,
                source="seed_data",
                effective_date=today,
            ),
        ]
        for r in rates:
            db.add(r)
        await db.flush()
        log.info("Exchange rates seeded", count=len(rates))

    await db.commit()
    log.info("Database seed completed successfully")
