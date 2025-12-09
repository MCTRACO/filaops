# License Activation System - User Guide

## How Users Activate Pro Features

When a user sees a Pro feature they want (like Advanced Analytics), here's how they activate it:

### Step 1: Navigate to License Page
- Go to **Admin → License** in the sidebar
- Or click "Activate License" button on any Pro feature page

### Step 2: Enter License Key
- Users receive a license key when they purchase Pro/Enterprise
- Format: `PRO-XXXX-XXXX-XXXX` (Pro) or `ENT-XXXX-XXXX-XXXX` (Enterprise)
- Enter the key in the activation form

### Step 3: Activation
- System validates the license key
- License is stored in database (hashed for security)
- User's tier is updated immediately
- All Pro features become accessible

### Step 4: Verification
- User can see their tier status on the License page
- Analytics and other Pro features are now accessible
- No restart required - changes take effect immediately

---

## For Testing (Development)

### Test License Keys
- **Pro Tier**: `TEST-PRO` or `PRO-1234-5678-9012`
- **Enterprise Tier**: `TEST-ENTERPRISE` or `ENT-1234-5678-9012`

### How It Works
1. User enters license key on `/admin/license` page
2. Backend validates key format
3. License stored in `licenses` table (hashed)
4. `get_current_tier()` checks database first, then environment variable
5. Frontend refreshes and shows Pro features

---

## Database Setup

**IMPORTANT**: Before license activation works, you need to create the licenses table:

```sql
-- Run this script in SQL Server
-- File: scripts/create_licenses_table.sql
```

Or run:
```bash
sqlcmd -S localhost\SQLEXPRESS -d FilaOps -i scripts/create_licenses_table.sql
```

---

## Architecture

### Priority Order for Tier Detection
1. **User's active license** (from `licenses` table) - **HIGHEST PRIORITY**
2. **Environment variable** (`TIER=pro` in `.env`) - For testing/self-hosted
3. **Default to OPEN** - If nothing else

### License Storage
- License keys are **hashed** (SHA256) before storage
- Never returned in full to frontend
- Linked to user account
- Can be revoked/deactivated

### Security
- License keys validated on backend only
- Keys never sent in full to frontend
- Database stores hashed version only
- Each user can have one active license per tier

---

## Future Enhancements (Pro Launch)

1. **Stripe Integration**: Generate license keys from Stripe subscriptions
2. **License Server**: Centralized validation for SaaS deployments
3. **Expiration Dates**: Automatic tier downgrade when license expires
4. **Multi-User Licenses**: Organization-level licenses
5. **Trial Periods**: Temporary Pro access for evaluation

---

## Current Implementation Status

✅ **Complete:**
- License activation endpoint
- License storage in database
- Tier detection from database
- Frontend license management page
- Test license key validation

⏳ **TODO (for production):**
- Stripe subscription integration
- License key generation system
- Expiration date handling
- License server for SaaS
- Organization-level licenses

---

## User Experience Flow

```
User sees Pro feature (e.g., Analytics)
    ↓
Clicks "Activate License" or goes to /admin/license
    ↓
Enters license key (received from purchase)
    ↓
Backend validates and stores license
    ↓
User's tier updated immediately
    ↓
Pro features become accessible
    ↓
No restart needed - instant activation!
```

---

## Testing the Flow

1. **Start with Open tier** (default)
2. Visit `/admin/analytics` - see Pro announcement
3. Go to `/admin/license`
4. Enter `TEST-PRO` or `PRO-1234-5678-9012`
5. Click "Activate License"
6. Page refreshes - tier should show "PRO"
7. Visit `/admin/analytics` again - should see analytics dashboard!

---

**The license activation system is ready for testing!** Users can now upgrade from Open to Pro/Enterprise by entering a license key.

