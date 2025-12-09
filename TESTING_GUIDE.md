# FilaOps Testing Guide - Phase 1 Migration

**What Changed:** MaterialInventory → Products + Inventory Migration  
**Status:** Ready for Testing  
**Database:** FilaOps

---

## 🎯 What Was Changed

### The Problem
Previously, you had **three competing data models** for items:
1. `Products` table - for finished goods
2. `MaterialInventory` table - for materials (PLA, PETG, etc.)
3. `Inventory` table - for stock tracking

This caused confusion and bugs.

### The Solution
**Unified Item Master:** Everything is now in the `Products` table:
- ✅ Finished goods → `Products` (as before)
- ✅ Materials → `Products` (NEW - materials are now products)
- ✅ Stock tracking → `Inventory` (linked to Products)

### Specific Changes Made

1. **Database Schema Updates**
   - Added `material_type_id` to `products` table
   - Added `color_id` to `products` table
   - Added `procurement_type` to `products` table
   - Added `unit` to `bom_lines` table
   - Added `is_cost_only` to `bom_lines` table

2. **API Changes**
   - ✅ NEW: `POST /api/v1/items/material` - Create material items
   - ✅ Materials API (`/api/v1/materials`) is now **read-only**
   - ✅ All material creation now goes through Items API

3. **Data Migration**
   - ✅ 146 MaterialInventory records → Products + Inventory
   - ✅ All materials now have Product records
   - ✅ All materials have Inventory records with quantities

---

## 🧪 Testing Checklist

### Phase 1: Basic Functionality

#### ✅ Test 1: Verify Database Migration
**Goal:** Confirm all materials were migrated correctly

1. **Check API Health**
   ```
   GET http://localhost:8000/health
   ```
   Should return: `{"status": "healthy"}`

2. **List All Items (including materials)**
   ```
   GET http://localhost:8000/api/v1/items
   ```
   **What to check:**
   - Should see materials in the list (SKUs starting with "MAT-")
   - Materials should have `item_type` set
   - Materials should have `material_type_id` and `color_id` populated

3. **Check Material Inventory**
   ```
   GET http://localhost:8000/api/v1/materials/inventory
   ```
   **What to check:**
   - Should see 146 material inventory records
   - Quantities should match what was in MaterialInventory

---

#### ✅ Test 2: Create a New Material Item
**Goal:** Verify the new material creation endpoint works

1. **Create a Material via Items API**
   ```
   POST http://localhost:8000/api/v1/items/material
   Content-Type: application/json
   
   {
     "material_type_code": "PLA_BASIC",
     "color_code": "BLK",
     "initial_qty_kg": 5.0,
     "cost_per_kg": 25.00
   }
   ```
   
   **IMPORTANT:** Field names are:
   - `material_type_code` (not `material_type`)
   - `color_code` (not `color_name`) 
   - `initial_qty_kg` (not `quantity_kg`)
   
   **Valid codes:** Check `/api/v1/materials/types` and `/api/v1/materials/colors` for valid codes
   **What to check:**
   - ✅ Returns 201 Created
   - ✅ Creates a Product record
   - ✅ Creates an Inventory record
   - ✅ SKU follows pattern: `MAT-PLA_BASIC-BLK` (or similar)
   - ✅ Product has `material_type_id` and `color_id` set
   
   **Troubleshooting 422 errors:**
   - Check field names match exactly: `material_type_code`, `color_code`, `initial_qty_kg`
   - Verify material type code exists: `GET /api/v1/materials/types`
   - Verify color code exists: `GET /api/v1/materials/colors?material_type=PLA_BASIC`

2. **Verify it appears in Items list**
   ```
   GET http://localhost:8000/api/v1/items?search=MAT-FDM-PLA_BASIC-BLK
   ```
   **What to check:**
   - ✅ Material appears in items list
   - ✅ Can be retrieved by ID

3. **Verify Inventory was created**
   ```
   GET http://localhost:8000/api/v1/inventory?product_id=<product_id>
   ```
   **What to check:**
   - ✅ Inventory record exists
   - ✅ Quantity matches (5.0 kg)

---

#### ✅ Test 3: Materials API is Read-Only
**Goal:** Verify old material creation endpoint is disabled

1. **Try to create via old endpoint (should fail)**
   ```
   POST http://localhost:8000/api/v1/materials/inventory
   ```
   **What to check:**
   - ✅ Returns 410 Gone (or 405 Method Not Allowed)
   - ✅ Error message directs to new endpoint

2. **Verify read operations still work**
   ```
   GET http://localhost:8000/api/v1/materials/types
   GET http://localhost:8000/api/v1/materials/colors
   GET http://localhost:8000/api/v1/materials/inventory
   ```
   **What to check:**
   - ✅ All GET requests still work
   - ✅ Data is correct

---

#### ✅ Test 4: BOM Creation with Materials
**Goal:** Verify BOMs can reference material products

1. **Get a material product ID**
   ```
   GET http://localhost:8000/api/v1/items?item_type=material
   ```
   Note a material product ID (e.g., `product_id: 123`)

2. **Create a BOM that uses the material**
   ```
   POST http://localhost:8000/api/v1/admin/boms
   Content-Type: application/json
   
   {
     "product_id": <some_finished_good_id>,
     "name": "Test BOM with Material",
     "lines": [
       {
         "component_id": <material_product_id>,
         "quantity": 0.5,
         "unit": "kg",
         "is_cost_only": false
       }
     ]
   }
   ```
   **What to check:**
   - ✅ BOM creates successfully
   - ✅ Material appears in BOM lines
   - ✅ Unit is saved correctly ("kg")
   - ✅ `is_cost_only` flag is saved

3. **Retrieve the BOM**
   ```
   GET http://localhost:8000/api/v1/admin/boms/<bom_id>
   ```
   **What to check:**
   - ✅ BOM includes material line
   - ✅ Material product details are correct
   - ✅ Quantity and unit are correct

---

#### ✅ Test 5: Material Lookup Functions
**Goal:** Verify material service functions work

1. **Test material availability check**
   ```
   GET http://localhost:8000/api/v1/materials/availability?material_type=PLA_BASIC&color=Black
   ```
   **What to check:**
   - ✅ Returns availability information
   - ✅ Quantity matches inventory

2. **Test material pricing**
   ```
   GET http://localhost:8000/api/v1/materials/pricing?material_type=PLA_BASIC&color=Black
   ```
   **What to check:**
   - ✅ Returns pricing information
   - ✅ Cost per kg is correct

---

### Phase 2: Integration Testing

#### ✅ Test 6: Quote-to-Order Flow (if applicable)
**Goal:** Verify quotes can convert to orders with materials

1. **Create a quote with materials**
   - Use the quote creation flow
   - Include materials in the quote

2. **Convert quote to order**
   - Accept the quote
   - Verify materials are correctly referenced

3. **Check BOM creation**
   - Verify BOM is created with material products
   - Verify quantities are correct

---

#### ✅ Test 7: Inventory Updates
**Goal:** Verify inventory tracking works for materials

1. **Update material inventory**
   ```
   PUT http://localhost:8000/api/v1/inventory/<inventory_id>
   {
     "quantity": 10.5
   }
   ```
   **What to check:**
   - ✅ Inventory updates correctly
   - ✅ Material availability reflects change

2. **Check inventory transactions**
   ```
   GET http://localhost:8000/api/v1/inventory/transactions?product_id=<material_product_id>
   ```
   **What to check:**
   - ✅ Transactions are recorded
   - ✅ History is maintained

---

### Phase 3: Edge Cases

#### ✅ Test 8: Duplicate Material Creation
**Goal:** Verify system handles duplicates correctly

1. **Try to create same material twice**
   ```
   POST http://localhost:8000/api/v1/items/material
   {
     "material_type": "PLA_BASIC",
     "color_name": "Black",
     ...
   }
   ```
   **What to check:**
   - ✅ Should either:
     - Return existing product (if duplicate detection works)
     - OR return error about duplicate SKU
   - ✅ No duplicate records created

---

#### ✅ Test 9: Material in BOM with Different Units
**Goal:** Verify unit handling works correctly

1. **Create BOM with material in kg**
   ```
   {
     "component_id": <material_id>,
     "quantity": 0.5,
     "unit": "kg"
   }
   ```

2. **Create BOM with material in different unit (if supported)**
   ```
   {
     "component_id": <material_id>,
     "quantity": 500,
     "unit": "g"  // grams
   }
   ```
   **What to check:**
   - ✅ Units are saved correctly
   - ✅ System handles unit conversions (if implemented)

---

## 🐛 What to Look For (Common Issues)

### Red Flags 🚩
- ❌ Materials don't appear in items list
- ❌ Material creation fails silently
- ❌ BOM creation fails when using materials
- ❌ Inventory quantities don't match
- ❌ API returns 500 errors
- ❌ Database errors in logs

### Success Indicators ✅
- ✅ Materials appear in unified items list
- ✅ Can create materials via `/items/material`
- ✅ BOMs can reference material products
- ✅ Inventory tracking works for materials
- ✅ Old Materials API still works for reads
- ✅ No database errors

---

## 📊 Testing Results Template

```
Date: ___________
Tester: ___________

Test 1: Database Migration
  [ ] Pass  [ ] Fail  Notes: ___________

Test 2: Create Material Item
  [ ] Pass  [ ] Fail  Notes: ___________

Test 3: Materials API Read-Only
  [ ] Pass  [ ] Fail  Notes: ___________

Test 4: BOM Creation with Materials
  [ ] Pass  [ ] Fail  Notes: ___________

Test 5: Material Lookup Functions
  [ ] Pass  [ ] Fail  Notes: ___________

Test 6: Quote-to-Order Flow
  [ ] Pass  [ ] Fail  Notes: ___________

Test 7: Inventory Updates
  [ ] Pass  [ ] Fail  Notes: ___________

Test 8: Duplicate Material Creation
  [ ] Pass  [ ] Fail  Notes: ___________

Test 9: Material Units in BOM
  [ ] Pass  [ ] Fail  Notes: ___________

Overall Status: [ ] Ready  [ ] Needs Fixes

Issues Found:
1. ___________
2. ___________
3. ___________
```

---

## 🚀 Quick Start Testing

**Fastest way to verify everything works:**

1. **Start the servers**
   ```powershell
   .\start-simple.ps1
   ```

2. **Open API docs**
   ```
   http://localhost:8000/docs
   ```

3. **Run these 3 quick tests:**
   - ✅ GET `/api/v1/items` - See materials in list
   - ✅ POST `/api/v1/items/material` - Create a material
   - ✅ GET `/api/v1/admin/boms` - Check BOMs work

If these 3 pass, the core migration is working! 🎉

---

## 📝 Notes

- **Database:** All tests use `FilaOps` database
- **Backend:** Running on `http://localhost:8000`
- **Frontend:** Running on `http://localhost:5173`
- **API Docs:** `http://localhost:8000/docs` (interactive testing)

---

**Questions?** Check the logs:
- Backend logs: Check the backend PowerShell window
- Database: Check SQL Server logs if needed

