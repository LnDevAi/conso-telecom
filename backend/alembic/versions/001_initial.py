"""Initial schema — all tables

Revision ID: 001_initial
Revises:
Create Date: 2026-05-28 00:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── countries ──────────────────────────────────────────────────────────────
    op.create_table(
        "countries",
        sa.Column("code", sa.String(3), primary_key=True),
        sa.Column("name_fr", sa.String(128), nullable=False),
        sa.Column("name_en", sa.String(128), nullable=False),
        sa.Column("default_currency", sa.String(8), nullable=False, server_default="XOF"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # ── operators ──────────────────────────────────────────────────────────────
    op.create_table(
        "operators",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column(
            "country_code",
            sa.String(3),
            sa.ForeignKey("countries.code", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("ussd_balance_code", sa.String(32), nullable=True),
        sa.Column("ussd_data_code", sa.String(32), nullable=True),
        sa.Column("logo_url", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.create_index("ix_operators_country_code", "operators", ["country_code"])

    # ── plan_type enum ─────────────────────────────────────────────────────────
    plan_type_enum = postgresql.ENUM(
        "DATA", "VOICE", "SMS", "COMBO", name="plan_type_enum", create_type=True
    )
    plan_type_enum.create(op.get_bind())

    # ── tariff_plans ───────────────────────────────────────────────────────────
    op.create_table(
        "tariff_plans",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "operator_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("operators.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column(
            "plan_type",
            postgresql.ENUM(
                "DATA", "VOICE", "SMS", "COMBO", name="plan_type_enum", create_type=False
            ),
            nullable=False,
        ),
        sa.Column("data_limit_mb", sa.Integer(), nullable=True),
        sa.Column("voice_limit_minutes", sa.Integer(), nullable=True),
        sa.Column("sms_limit", sa.Integer(), nullable=True),
        sa.Column("price", sa.Numeric(14, 4), nullable=False),
        sa.Column("currency", sa.String(8), nullable=False, server_default="XOF"),
        sa.Column("validity_days", sa.Integer(), nullable=False, server_default="30"),
        sa.Column("valid_from", sa.Date(), nullable=True),
        sa.Column("valid_until", sa.Date(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_tariff_plans_operator_id", "tariff_plans", ["operator_id"])

    # ── resource_type enum ─────────────────────────────────────────────────────
    resource_type_enum = postgresql.ENUM(
        "DATA_MB",
        "CALL_ONNET_MIN",
        "CALL_OFFNET_MIN",
        "CALL_INTL_MIN",
        "SMS_ONNET",
        "SMS_OFFNET",
        name="resource_type_enum",
        create_type=True,
    )
    resource_type_enum.create(op.get_bind())

    # ── unit_tariffs ───────────────────────────────────────────────────────────
    op.create_table(
        "unit_tariffs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "operator_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("operators.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "resource_type",
            postgresql.ENUM(
                "DATA_MB",
                "CALL_ONNET_MIN",
                "CALL_OFFNET_MIN",
                "CALL_INTL_MIN",
                "SMS_ONNET",
                "SMS_OFFNET",
                name="resource_type_enum",
                create_type=False,
            ),
            nullable=False,
        ),
        sa.Column("price", sa.Numeric(14, 6), nullable=False),
        sa.Column("currency", sa.String(8), nullable=False, server_default="XOF"),
        sa.Column("valid_from", sa.Date(), nullable=True),
        sa.Column("valid_until", sa.Date(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_unit_tariffs_operator_id", "unit_tariffs", ["operator_id"])

    # ── ai_providers ───────────────────────────────────────────────────────────
    op.create_table(
        "ai_providers",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column("website", sa.Text(), nullable=True),
        sa.Column("usage_api_endpoint", sa.Text(), nullable=True),
        sa.Column("usage_api_doc_url", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # ── ai_models ──────────────────────────────────────────────────────────────
    op.create_table(
        "ai_models",
        sa.Column("id", sa.String(128), primary_key=True),
        sa.Column(
            "provider_id",
            sa.String(64),
            sa.ForeignKey("ai_providers.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("input_price_per_mtok_usd", sa.Numeric(12, 6), nullable=False),
        sa.Column("output_price_per_mtok_usd", sa.Numeric(12, 6), nullable=False),
        sa.Column("context_window", sa.Integer(), nullable=True),
        sa.Column("valid_from", sa.Date(), nullable=True),
        sa.Column("valid_until", sa.Date(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_ai_models_provider_id", "ai_models", ["provider_id"])

    # ── exchange_rates ─────────────────────────────────────────────────────────
    op.create_table(
        "exchange_rates",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("from_currency", sa.String(8), nullable=False),
        sa.Column("to_currency", sa.String(8), nullable=False),
        sa.Column("rate", sa.Numeric(18, 8), nullable=False),
        sa.Column("source", sa.String(128), nullable=False, server_default="manual"),
        sa.Column("effective_date", sa.Date(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index(
        "ix_exchange_rates_pair_date",
        "exchange_rates",
        ["from_currency", "to_currency", "effective_date"],
    )

    # ── admin_users ────────────────────────────────────────────────────────────
    op.create_table(
        "admin_users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_admin_users_email", "admin_users", ["email"])


def downgrade() -> None:
    op.drop_table("admin_users")
    op.drop_table("exchange_rates")
    op.drop_table("ai_models")
    op.drop_table("ai_providers")
    op.drop_table("unit_tariffs")
    op.drop_table("tariff_plans")
    op.drop_table("operators")
    op.drop_table("countries")

    # Drop custom enum types
    op.execute("DROP TYPE IF EXISTS plan_type_enum")
    op.execute("DROP TYPE IF EXISTS resource_type_enum")
