# Core Product Scope - FilaOps Open Source

**Date:** 2025-01-15  
**Status:** ✅ **CURRENT FOCUS**

---

## What We're Building

### ✅ Core ERP (Current Focus)
- **Admin Dashboard** - Full React UI for internal operations
- **Product Catalog** - SKUs, variants, material-aware costing
- **Bill of Materials** - Multi-level BOMs with filament and hardware
- **Inventory Management** - Stock levels, allocations, FIFO tracking
- **Sales Orders** - Order management (admin-created or imported)
- **Production Orders** - Manufacturing workflow with operations
- **MRP** - Material requirements planning
- **Work Centers & Routing** - Capacity planning and operation sequences
- **Traceability** - Serial numbers, lot tracking (FDA/ISO ready)

### ❌ Not in Core (Pro Features - Future)
- Customer Quote Portal (Pro 2026)
- Customer-facing UI
- Multi-material quoting
- E-commerce integrations (Squarespace/WooCommerce webhooks)
- Payment processing
- Shipping integrations

---

## Authorization Model (Core Product)

### Current Implementation
- **All endpoints**: Admin-only access
- **User model**: Supports `admin` and `customer` account types, but only `admin` is used
- **Customer endpoints**: Exist in backend but are for future Pro version

### Recommendation
- Keep customer endpoints in backend (for future Pro)
- Mark them clearly as "Pro feature" in code/docs
- Focus authorization on admin-only for core product
- Simplify user checks to assume admin access

---

## Next Steps

1. ✅ Keep current authorization (admin can see all orders)
2. ✅ Mark customer portal endpoints as "Pro feature" in docstrings
3. ✅ Focus on core ERP functionality
4. ⏳ Future: Build Pro version with customer portal UI

---

**Note**: The backend has customer portal endpoints because the full system vision includes Pro features, but the **core open source product is admin-only**.

