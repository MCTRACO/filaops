"""
Feature flags and tier information endpoints
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.api.v1.endpoints.auth import get_current_user
from app.models.user import User
from app.core.features import (
    get_current_tier,
    get_available_features,
    Tier
)
from pydantic import BaseModel

router = APIRouter(prefix="/features", tags=["features"])


class TierInfo(BaseModel):
    tier: str
    features: list[str]
    is_pro: bool
    is_enterprise: bool


@router.get("/current", response_model=TierInfo)
async def get_current_tier_info(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's tier and available features"""
    tier = get_current_tier(db, current_user)
    features = get_available_features(tier)
    
    return TierInfo(
        tier=tier.value,
        features=features,
        is_pro=tier in (Tier.PRO, Tier.ENTERPRISE),
        is_enterprise=tier == Tier.ENTERPRISE
    )

