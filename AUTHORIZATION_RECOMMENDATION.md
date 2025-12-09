# Sales Order Authorization Model - Recommendation

## Current State

**Viewing:**
- ✅ Admins can see all orders
- ✅ Users can only see their own orders
- ✅ This is correctly implemented

**Editing:**
- ❌ **SECURITY ISSUE**: Most update endpoints have NO authorization checks
- ❌ `update_order_status` - Has TODO comment, currently allows any user
- ❌ `update_payment_info` - No authorization check
- ❌ `update_shipping_info` - No authorization check
- ✅ `cancel_sales_order` - Only allows order owner (correct)

---

## Recommendation: **Option 1** (Current Viewing Model + Fix Editing)

### Viewing Rules:
- **Admins**: Can see ALL orders (needed for production management, fulfillment, etc.)
- **Users**: Can only see their own orders (privacy/security)

### Editing Rules:
- **Admins**: Can edit any order (status, payment, shipping, notes)
- **Users**: Can ONLY cancel their own pending orders (via cancel endpoint)
- **Users**: Cannot edit status, payment, or shipping info

---

## Why Option 1 is Better:

### ✅ **Privacy & Security**
- Customers shouldn't see other customers' orders
- Prevents information leakage
- Standard ERP/MRP practice

### ✅ **Clear Separation of Concerns**
- Admins manage production/fulfillment → need to see all orders
- Customers track their own orders → only need their own
- Less confusion in the UI

### ✅ **Compliance**
- Better for GDPR/privacy regulations
- Reduces risk of accidental data exposure

### ❌ **Why Option 2 is NOT Recommended:**
- **Privacy violation**: Customers seeing other customers' orders
- **Confusion**: "I can see it but can't change it" is poor UX
- **Security risk**: More data exposed = more attack surface
- **Not standard**: Most ERPs restrict order visibility to owner + admins

---

## Implementation Plan

1. **Keep viewing as-is** ✅ (already correct)
2. **Fix editing endpoints** - Add admin-only checks:
   - `update_order_status` → Admin only
   - `update_payment_info` → Admin only  
   - `update_shipping_info` → Admin only
   - `cancel_sales_order` → Keep as owner-only (correct)
   - `generate_production_orders` → Admin only

---

## Exception: Customer Self-Service

If you want customers to be able to do some actions:
- ✅ **Cancel pending orders** (already implemented)
- ✅ **View order status** (read-only, already implemented)
- ❌ **Edit order details** (should be admin-only)
- ❌ **Change shipping address** (should be admin-only after confirmation)

---

**Conclusion**: Keep Option 1 (current viewing model) and fix the editing endpoints to be admin-only. This is the most secure and standard approach for an ERP system.

