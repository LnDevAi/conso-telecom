"""Tests for public tariff endpoints."""

from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health(client: AsyncClient):
    resp = await client.get("/api/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["version"] == "2.0.0"


@pytest.mark.asyncio
async def test_countries_empty(client: AsyncClient):
    resp = await client.get("/api/v1/tariffs/countries")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


@pytest.mark.asyncio
async def test_countries_returns_bf(client: AsyncClient, seeded_db):
    resp = await client.get("/api/v1/tariffs/countries")
    assert resp.status_code == 200
    codes = [c["code"] for c in resp.json()]
    assert "BF" in codes


@pytest.mark.asyncio
async def test_operators_by_country(client: AsyncClient, seeded_db):
    resp = await client.get("/api/v1/tariffs/operators/BF")
    assert resp.status_code == 200
    ops = resp.json()
    assert len(ops) >= 1
    assert ops[0]["country_code"] == "BF"


@pytest.mark.asyncio
async def test_operators_with_tariff_plans(client: AsyncClient, seeded_db):
    resp = await client.get("/api/v1/tariffs/operators/BF")
    assert resp.status_code == 200
    ops = resp.json()
    assert len(ops) >= 1
    # At least one operator should have tariff plans
    has_plan = any(len(op["tariff_plans"]) > 0 for op in ops)
    assert has_plan


@pytest.mark.asyncio
async def test_operators_with_unit_tariffs(client: AsyncClient, seeded_db):
    resp = await client.get("/api/v1/tariffs/operators/BF")
    assert resp.status_code == 200
    ops = resp.json()
    has_unit = any(len(op["unit_tariffs"]) > 0 for op in ops)
    assert has_unit


@pytest.mark.asyncio
async def test_operators_unknown_country(client: AsyncClient, seeded_db):
    resp = await client.get("/api/v1/tariffs/operators/XX")
    assert resp.status_code == 200
    assert resp.json() == []


@pytest.mark.asyncio
async def test_ai_providers(client: AsyncClient, seeded_db):
    resp = await client.get("/api/v1/tariffs/ai-providers")
    assert resp.status_code == 200
    providers = resp.json()
    assert len(providers) >= 1
    ids = [p["id"] for p in providers]
    assert "anthropic" in ids


@pytest.mark.asyncio
async def test_ai_providers_with_models(client: AsyncClient, seeded_db):
    resp = await client.get("/api/v1/tariffs/ai-providers")
    assert resp.status_code == 200
    providers = resp.json()
    anthropic = next((p for p in providers if p["id"] == "anthropic"), None)
    assert anthropic is not None
    assert len(anthropic["models"]) >= 1
    assert anthropic["models"][0]["input_price_per_mtok_usd"] > 0


@pytest.mark.asyncio
async def test_exchange_rates(client: AsyncClient, seeded_db):
    resp = await client.get("/api/v1/tariffs/exchange-rates")
    assert resp.status_code == 200
    rates = resp.json()
    assert len(rates) >= 1
    assert rates[0]["rate"] > 0


@pytest.mark.asyncio
async def test_updates_no_since(client: AsyncClient, seeded_db):
    resp = await client.get("/api/v1/tariffs/updates")
    assert resp.status_code == 200
    data = resp.json()
    assert "server_time" in data
    assert "tariff_plans" in data
    assert "unit_tariffs" in data
    assert "ai_models" in data
    assert "exchange_rates" in data


@pytest.mark.asyncio
async def test_updates_with_since(client: AsyncClient, seeded_db):
    resp = await client.get("/api/v1/tariffs/updates?since=2020-01-01T00:00:00Z")
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data["tariff_plans"], list)
