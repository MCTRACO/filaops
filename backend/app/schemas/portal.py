"""
Portal Pydantic Schemas

Schemas for the B2B wholesale portal integration.
"""
from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import datetime


# ============================================================================
# Access Request Schemas
# ============================================================================

class AccessRequestCreate(BaseModel):
    """Submit a new access request from the Portal"""
    business_name: str = Field(..., min_length=1, max_length=200)
    contact_name: str = Field(..., min_length=1, max_length=100)
    contact_email: EmailStr
    contact_phone: Optional[str] = Field(None, max_length=50)

    # Address
    address_line1: Optional[str] = Field(None, max_length=255)
    address_line2: Optional[str] = Field(None, max_length=255)
    city: Optional[str] = Field(None, max_length=100)
    state: Optional[str] = Field(None, max_length=50)
    zip_code: Optional[str] = Field(None, max_length=20)
    country: Optional[str] = Field("USA", max_length=100)

    # Optional message
    message: Optional[str] = Field(None, max_length=2000)

    # CAPTCHA token (validated by Portal before calling this API)
    # We trust Portal to have validated this, but could add server-side check
    turnstile_verified: bool = Field(default=False)


class AccessRequestResponse(BaseModel):
    """Access request details (for Portal polling)"""
    id: int
    status: str  # pending, approved, denied

    # Business info
    business_name: str
    contact_name: str
    contact_email: str
    contact_phone: Optional[str] = None

    # Address
    address_line1: Optional[str] = None
    address_line2: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    zip_code: Optional[str] = None
    country: Optional[str] = None

    message: Optional[str] = None

    # Approval info (if approved)
    customer_id: Optional[int] = None
    approved_at: Optional[datetime] = None

    # Denial info (if denied)
    denial_reason: Optional[str] = None

    # Password setup (if approved and token generated)
    password_setup_token: Optional[str] = None
    password_setup_expires_at: Optional[datetime] = None
    password_setup_completed_at: Optional[datetime] = None

    # Timestamps
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class AccessRequestListItem(BaseModel):
    """Summary for admin list view"""
    id: int
    status: str
    business_name: str
    contact_name: str
    contact_email: str
    contact_phone: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    message: Optional[str] = None
    created_at: datetime
    approved_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class AccessRequestApprove(BaseModel):
    """Approve an access request"""
    # Optional: assign to existing customer or create new
    # If not provided, creates new customer from request data
    existing_customer_id: Optional[int] = None


class AccessRequestDeny(BaseModel):
    """Deny an access request"""
    reason: Optional[str] = Field(None, max_length=1000)


class AccessRequestApprovalResponse(BaseModel):
    """Response after approving a request"""
    id: int
    status: str
    customer_id: int
    customer_email: str
    password_setup_token: str
    password_setup_expires_at: datetime
    message: str = "Access request approved. Password setup email should be sent by Portal."

    class Config:
        from_attributes = True


# ============================================================================
# Password Setup Schemas
# ============================================================================

class PasswordSetupRequest(BaseModel):
    """Set password using the setup token"""
    token: str
    password: str = Field(..., min_length=8, max_length=128)


class PasswordSetupResponse(BaseModel):
    """Response after setting password"""
    success: bool
    message: str
    customer_email: Optional[str] = None
