# Sales Order Line Schema Fix

**Date:** 2025-01-15  
**Status:** ✅ **FIXED**

---

## Problem

The `sales_order_lines` table schema doesn't match the SQLAlchemy model:

**Model Expected:**
- `line_number`
- `total_price`
- `product_sku`
- `product_name`
- `created_at`

**Database Actually Has:**
- `total` (not `total_price`)
- No `line_number`
- No `product_sku`
- No `product_name`
- No `created_at`

This caused errors when trying to load sales order details:
```
Invalid column name 'line_number'
Invalid column name 'total_price'
Invalid column name 'product_sku'
Invalid column name 'product_name'
Invalid column name 'created_at'
```

---

## Solution

1. **Updated SalesOrderLine Model** to match actual database schema:
   - Changed `total_price` → `total`
   - Removed `line_number`, `product_sku`, `product_name`, `created_at` from model
   - These are now computed in the API layer

2. **Updated `build_sales_order_response` function**:
   - Orders lines by `id` (since `line_number` doesn't exist)
   - Calculates `line_number` from position
   - Gets `product_sku` and `product_name` from Product relationship
   - Uses `total` column and converts to `total_price` for response

3. **Updated `get_sales_order_details` endpoint**:
   - Now uses `build_sales_order_response` helper instead of returning order directly
   - This ensures proper serialization with computed fields

4. **Updated SalesOrderLine creation**:
   - Uses `total` instead of `total_price`
   - Removed fields that don't exist in database

---

## Files Modified

- `backend/app/models/sales_order.py` - Updated model to match DB schema
- `backend/app/api/v1/endpoints/sales_orders.py` - Updated helper function and endpoint

---

**Status:** Fixed! Sales order detail endpoint should now work correctly. ✅

