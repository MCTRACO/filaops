"""
Portal Authentication

Validates API key from the B2B wholesale portal.
Uses constant-time comparison to prevent timing attacks.
"""
import hmac
from fastapi import Header, HTTPException, status
from app.core.config import settings


def verify_portal_api_key(
    x_api_key: str = Header(..., alias="X-API-Key", description="Portal API key")
) -> bool:
    """
    Validate Portal's API key.

    The Portal sends its API key in the X-API-Key header.
    This key should be configured in PORTAL_API_KEY environment variable.

    Uses constant-time comparison to prevent timing attacks.

    Returns:
        True if valid

    Raises:
        HTTPException 401 if invalid or missing
    """
    expected = getattr(settings, 'PORTAL_API_KEY', None)

    if not expected:
        # No portal key configured - portal integration disabled
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Portal integration not configured"
        )

    # Validate key format (should start with fops_)
    if not x_api_key or not x_api_key.startswith('fops_'):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key format"
        )

    # Constant-time comparison prevents timing attacks
    if not hmac.compare_digest(x_api_key, expected):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key"
        )

    return True


def get_portal_api_key_optional(
    x_api_key: str = Header(None, alias="X-API-Key")
) -> str | None:
    """
    Get Portal API key if provided (optional).

    Use this for endpoints that can be accessed by both
    Portal (via API key) and admin users (via JWT).
    """
    return x_api_key
