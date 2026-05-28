from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import (
    create_access_token,
    get_current_admin,
    verify_password,
)
from app.models.admin_user import AdminUser
from app.schemas.admin_user import AdminUserRead, LoginRequest, Token

router = APIRouter(prefix="/admin/auth", tags=["admin auth"])


@router.post("/login", response_model=Token, summary="Admin login — returns JWT")
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(AdminUser).where(AdminUser.email == body.email)
    )
    user = result.scalar_one_or_none()
    if user is None or not verify_password(body.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Compte désactivé",
        )
    token = create_access_token(subject=user.email)
    return Token(access_token=token)


@router.get("/me", response_model=AdminUserRead, summary="Current admin info")
async def me(current_user: AdminUser = Depends(get_current_admin)):
    return current_user
