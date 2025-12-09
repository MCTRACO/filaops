# Test Order Setup - OrderDetail Testing

**Date:** 2025-01-15  
**Status:** ✅ **READY FOR TESTING**

---

## Test Order Created

**Order ID:** 47  
**Order Number:** SO-2025-021  
**Product ID:** 525 (TEST-001 - Test Product with BOM)  
**BOM ID:** 64  
**Quantity:** 10 units

**View in UI:** http://localhost:5173/admin/orders/47

---

## What to Test

1. **Order Detail Page Loads**
   - Navigate to `/admin/orders/47`
   - Should show order summary

2. **MRP Explosion**
   - Should show material requirements from BOM
   - Current BOM has 1 line: COMP-KEYRING (4 EA per unit)
   - For 10 units = 40 EA total

3. **Material Requirements Table**
   - Component: COMP-KEYRING
   - Required: 40 EA
   - On Hand: (check inventory)
   - Available: (check inventory)
   - Shortage: (if any)

4. **Capacity Requirements**
   - Should show routing operations if routing exists
   - Currently no routing (optional)

5. **Create Work Order Button**
   - Should be enabled
   - Click to create production order

---

## Current BOM Structure

**BOM-0001** for TEST-001:
- Line 1: COMP-KEYRING - 4 EA per unit

**For 10 units:**
- Total COMP-KEYRING needed: 40 EA

---

## Next Steps

1. Add material line to BOM (PLA/PETG)
2. Add routing to product (optional)
3. Test MRP explosion in UI
4. Verify material requirements calculation
5. Test "Create Work Order" functionality

---

**Note:** The order is `quote_based` type, so product_id comes from the linked quote. The OrderDetail page now fetches the quote to get the product_id for MRP explosion.

