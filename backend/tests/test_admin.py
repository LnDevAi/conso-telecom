"""Tests for admin auth and CRUD endpoints."""

from __future__ import annotations

import pytest
from httpx import AsyncClient


async def get_token(client: AsyncClient) -> str:
    resp = await client.post(
        "/api/v1/admin/auth/login",
        json={"email": "admin@test.com", "password": "test1234"},
    )
    assert resp.status_code == 200, resp.text
    return resp.json()["access_token"]


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient, seeded_db):
    resp = await client.post(
        "/api/v1/admin/auth/login",
        json={"email": "admin@test.com", "password": "test1234"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient, seeded_db):
    resp = await client.post(
        "/api/v1/admin/auth/login",
        json={"email": "admin@test.com", "password": "wrongpassword"},
    )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_login_unknown_email(client: AsyncClient, seeded_db):
    resp = await client.post(
        "/api/v1/admin/auth/login",
        json={"email": "nobody@test.com", "password": "test1234"},
    )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_me_endpoint(client: AsyncClient, seeded_db):
    token = await get_token(client)
    resp = await client.get(
        "/api/v1/admin/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["email"] == "admin@test.com"


@pytest.mark.asyncio
async def test_protected_without_token(client: AsyncClient, seeded_db):
    resp = await client.get("/api/v1/admin/countries")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_create_and_list_country(client: AsyncClient, seeded_db):
    token = await get_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    resp = await client.post(
        "/api/v1/admin/countries",
        json={"code": "CI", "name_fr": "Côte d'Ivoire", "name_en": "Ivory Coast", "default_currency": "XOF"},
        headers=headers,
    )
    assert resp.status_code == 201
    assert resp.json()["code"] == "CI"

    resp = await client.get("/api/v1/admin/countries", headers=headers)
    assert resp.status_code == 200
    codes = [c["code"] for c in resp.json()]
    assert "CI" in codes


@pytest.mark.asyncio
async def test_update_country(client: AsyncClient, seeded_db):
    token = await get_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    resp = await client.patch(
        "/api/v1/admin/countries/BF",
        json={"name_en": "Burkina Faso (updated)"},
        headers=headers,
    )
    assert resp.status_code == 200
    assert "updated" in resp.json()["name_en"]


@pytest.mark.asyncio
async def test_list_ai_providers_admin(client: AsyncClient, seeded_db):
    token = await get_token(client)
    resp = await client.get(
        "/api/v1/admin/ai/providers",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert len(resp.json()) >= 1


@pytest.mark.asyncio
async def test_list_exchange_rates_admin(client: AsyncClient, seeded_db):
    token = await get_token(client)
    resp = await client.get(
        "/api/v1/admin/exchange-rates",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)
