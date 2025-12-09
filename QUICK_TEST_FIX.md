# Quick Test Fix - Material Creation Endpoint

## The Problem
The testing guide had **wrong field names**. The endpoint expects different field names than what was documented.

## Correct Field Names

The `POST /api/v1/items/material` endpoint expects:

```json
{
  "material_type_code": "PLA_BASIC",    // NOT "material_type"
  "color_code": "BLK",                  // NOT "color_name"  
  "initial_qty_kg": 5.0,                // NOT "quantity_kg"
  "cost_per_kg": 25.00,                 // Optional
  "selling_price": 30.00,               // Optional
  "category_id": null                   // Optional
}
```

## How to Get Valid Codes

Before testing, get valid material type codes and color codes:

### 1. Get Material Type Codes
```
GET http://localhost:8000/api/v1/materials/types
```

This returns all available material types with their codes (e.g., `PLA_BASIC`, `PETG_HF`, `ABS`, etc.)

### 2. Get Color Codes  
```
GET http://localhost:8000/api/v1/materials/colors
```

Or for a specific material:
```
GET http://localhost:8000/api/v1/materials/colors?material_type=PLA_BASIC
```

This returns color codes (e.g., `BLK`, `WHT`, `RED`, etc.)

## Corrected Test Example

```json
{
  "material_type_code": "PLA_BASIC",
  "color_code": "BLK",
  "initial_qty_kg": 5.0,
  "cost_per_kg": 25.00
}
```

## Why You Got 422 Errors

422 = Validation Error

This happens when:
- Field names are wrong (e.g., `material_type` instead of `material_type_code`)
- Field values are invalid (e.g., material type code doesn't exist)
- Required fields are missing

## Debugging Steps

1. **Check the API docs** at `http://localhost:8000/docs`
   - Click on `POST /api/v1/items/material`
   - Click "Try it out"
   - Look at the "Request body" schema - it shows the exact field names

2. **Get valid codes first:**
   ```
   GET /api/v1/materials/types
   GET /api/v1/materials/colors
   ```

3. **Use the exact field names from the schema:**
   - `material_type_code` (string, required)
   - `color_code` (string, required)
   - `initial_qty_kg` (decimal, optional, default 0)
   - `cost_per_kg` (decimal, optional)
   - `selling_price` (decimal, optional)
   - `category_id` (integer, optional)

## Quick Test (Copy-Paste Ready)

1. **First, get valid codes:**
   ```
   GET http://localhost:8000/api/v1/materials/types
   ```
   Pick a material type code (e.g., `PLA_BASIC`)

   ```
   GET http://localhost:8000/api/v1/materials/colors?material_type=PLA_BASIC
   ```
   Pick a color code (e.g., `BLK`)

2. **Then create the material:**
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

This should return **201 Created** ✅

