from __future__ import annotations

import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.security import get_current_admin
from app.models.operator import Operator
from app.models.tariff_plan import TariffPlan
from app.models.unit_tariff import UnitTariff
from app.schemas.operator import OperatorCreate, OperatorRead, OperatorReadWithTariffs, OperatorUpdate
from app.schemas.tariff_plan import TariffPlanCreate, TariffPlanRead, TariffPlanUpdate
from app.schemas.unit_tariff import UnitTariffCreate, UnitTariffRead, UnitTariffUpdate

router = APIRouter(
    prefix="/admin/operators",
    tags=["admin operators"],
    dependencies=[Depends(get_current_admin)],
)


# ── Operators CRUD ─────────────────────────────────────────────────────────────

@router.get("", response_model=List[OperatorReadWithTariffs])
async def list_operators(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Operator)
        .options(selectinload(Operator.tariff_plans), selectinload(Operator.unit_tariffs))
        .order_by(Operator.name)
    )
    return result.scalars().all()


@router.post("", response_model=OperatorRead, status_code=status.HTTP_201_CREATED)
async def create_operator(body: OperatorCreate, db: AsyncSession = Depends(get_db)):
    operator = Operator(**body.model_dump())
    db.add(operator)
    await db.flush()
    await db.refresh(operator)
    return operator


@router.get("/{operator_id}", response_model=OperatorReadWithTariffs)
async def get_operator(operator_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Operator)
        .where(Operator.id == operator_id)
        .options(selectinload(Operator.tariff_plans), selectinload(Operator.unit_tariffs))
    )
    operator = result.scalar_one_or_none()
    if not operator:
        raise HTTPException(status_code=404, detail="Opérateur introuvable")
    return operator


@router.patch("/{operator_id}", response_model=OperatorRead)
async def update_operator(
    operator_id: uuid.UUID, body: OperatorUpdate, db: AsyncSession = Depends(get_db)
):
    operator = await db.get(Operator, operator_id)
    if not operator:
        raise HTTPException(status_code=404, detail="Opérateur introuvable")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(operator, field, value)
    await db.flush()
    await db.refresh(operator)
    return operator


@router.delete("/{operator_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_operator(operator_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    operator = await db.get(Operator, operator_id)
    if not operator:
        raise HTTPException(status_code=404, detail="Opérateur introuvable")
    await db.delete(operator)


# ── Tariff Plans (nested under operator) ──────────────────────────────────────

@router.get("/{operator_id}/plans", response_model=List[TariffPlanRead])
async def list_plans(operator_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(TariffPlan)
        .where(TariffPlan.operator_id == operator_id)
        .order_by(TariffPlan.name)
    )
    return result.scalars().all()


@router.post(
    "/{operator_id}/plans",
    response_model=TariffPlanRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_plan(
    operator_id: uuid.UUID, body: TariffPlanCreate, db: AsyncSession = Depends(get_db)
):
    plan = TariffPlan(**{**body.model_dump(), "operator_id": operator_id})
    db.add(plan)
    await db.flush()
    await db.refresh(plan)
    return plan


@router.patch("/{operator_id}/plans/{plan_id}", response_model=TariffPlanRead)
async def update_plan(
    operator_id: uuid.UUID,
    plan_id: uuid.UUID,
    body: TariffPlanUpdate,
    db: AsyncSession = Depends(get_db),
):
    plan = await db.get(TariffPlan, plan_id)
    if not plan or plan.operator_id != operator_id:
        raise HTTPException(status_code=404, detail="Forfait introuvable")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(plan, field, value)
    await db.flush()
    await db.refresh(plan)
    return plan


@router.delete("/{operator_id}/plans/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_plan(
    operator_id: uuid.UUID, plan_id: uuid.UUID, db: AsyncSession = Depends(get_db)
):
    plan = await db.get(TariffPlan, plan_id)
    if not plan or plan.operator_id != operator_id:
        raise HTTPException(status_code=404, detail="Forfait introuvable")
    await db.delete(plan)


# ── Unit Tariffs (nested under operator) ──────────────────────────────────────

@router.get("/{operator_id}/unit-tariffs", response_model=List[UnitTariffRead])
async def list_unit_tariffs(operator_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(UnitTariff)
        .where(UnitTariff.operator_id == operator_id)
        .order_by(UnitTariff.resource_type)
    )
    return result.scalars().all()


@router.post(
    "/{operator_id}/unit-tariffs",
    response_model=UnitTariffRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_unit_tariff(
    operator_id: uuid.UUID, body: UnitTariffCreate, db: AsyncSession = Depends(get_db)
):
    ut = UnitTariff(**{**body.model_dump(), "operator_id": operator_id})
    db.add(ut)
    await db.flush()
    await db.refresh(ut)
    return ut


@router.patch(
    "/{operator_id}/unit-tariffs/{tariff_id}", response_model=UnitTariffRead
)
async def update_unit_tariff(
    operator_id: uuid.UUID,
    tariff_id: uuid.UUID,
    body: UnitTariffUpdate,
    db: AsyncSession = Depends(get_db),
):
    ut = await db.get(UnitTariff, tariff_id)
    if not ut or ut.operator_id != operator_id:
        raise HTTPException(status_code=404, detail="Tarif unitaire introuvable")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(ut, field, value)
    await db.flush()
    await db.refresh(ut)
    return ut


@router.delete(
    "/{operator_id}/unit-tariffs/{tariff_id}", status_code=status.HTTP_204_NO_CONTENT
)
async def delete_unit_tariff(
    operator_id: uuid.UUID,
    tariff_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    ut = await db.get(UnitTariff, tariff_id)
    if not ut or ut.operator_id != operator_id:
        raise HTTPException(status_code=404, detail="Tarif unitaire introuvable")
    await db.delete(ut)
