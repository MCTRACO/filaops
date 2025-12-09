# Step-by-Step: Create a Material Item

## The Error You're Seeing

The "JSON decode error" with field "42" suggests the request body format is wrong. You might be:
1. Using the wrong endpoint
2. Sending the response schema instead of request schema
3. JSON formatting issue

## Correct Steps

### Step 1: Get Valid Material Type Codes

**Endpoint:** `GET /api/v1/materials/types`

**In API Docs:**
1. Go to `http://localhost:8000/docs`
2. Find `GET /api/v1/materials/types`
3. Click "Try it out"
4. Click "Execute"
5. Copy a material type code from the response (e.g., `PLA_BASIC`, `PETG_HF`)

### Step 2: Get Valid Color Codes

**Endpoint:** `GET /api/v1/materials/colors?material_type=PLA_BASIC`

**In API Docs:**
1. Find `GET /api/v1/materials/colors`
2. Click "Try it out"
3. Enter `material_type` parameter: `PLA_BASIC`
4. Click "Execute"
5. Copy a color code from the response (e.g., `BLK`, `WHT`)

### Step 3: Create the Material

**Endpoint:** `POST /api/v1/items/material`

**IMPORTANT:** Make sure you're using `/items/material` NOT `/items`

**In API Docs:**
1. Find `POST /api/v1/items/material` (scroll down, it's after the regular items endpoints)
2. Click "Try it out"
3. **Clear the example JSON** (it might show response schema)
4. Paste this EXACT JSON:

```json
{
  "material_type_code": "PLA_BASIC",
  "color_code": "BLK",
  "initial_qty_kg": 5.0,
  "cost_per_kg": 25.00
}
```

5. Click "Execute"

## Correct Request Body (Copy This)

```json
{
  "material_type_code": "PLA_BASIC",
  "color_code": "BLK",
  "initial_qty_kg": 5.0,
  "cost_per_kg": 25.00
}
```

**Field breakdown:**
- `material_type_code`: String (required) - e.g., "PLA_BASIC"
- `color_code`: String (required) - e.g., "BLK" 
- `initial_qty_kg`: Number (optional) - e.g., 5.0
- `cost_per_kg`: Number (optional) - e.g., 25.00

## Common Mistakes

### ❌ Wrong: Using POST /items
```
POST /api/v1/items  ← This is for regular items, not materials
```

### ✅ Correct: Using POST /items/material
```
POST /api/v1/items/material  ← This is for materials
```

### ❌ Wrong: Using response schema
```json
{
  "id": 0,
  "sku": "string",
  "name": "string",
  ...
}
```

### ✅ Correct: Using request schema
```json
{
  "material_type_code": "PLA_BASIC",
  "color_code": "BLK",
  "initial_qty_kg": 5.0
}
```

## Using cURL (Alternative)

If API docs are confusing, use cURL:

```bash
curl -X POST "http://localhost:8000/api/v1/items/material" \
  -H "Content-Type: application/json" \
  -d '{
    "material_type_code": "PLA_BASIC",
    "color_code": "BLK",
    "initial_qty_kg": 5.0,
    "cost_per_kg": 25.00
  }'
```

## Expected Response (201 Created)

```json
{
  "id": 123,
  "sku": "MAT-PLA_BASIC-BLK",
  "name": "PLA Basic - Black",
  "item_type": "supply",
  "procurement_type": "buy",
  "unit": "kg",
  "material_type_id": 14,
  "color_id": 137,
  ...
}
```

## Still Getting Errors?

1. **Check you're using the right endpoint:**
   - ✅ `POST /api/v1/items/material`
   - ❌ NOT `POST /api/v1/items`

2. **Verify material type code exists:**
   - Run `GET /api/v1/materials/types` first

3. **Verify color code exists:**
   - Run `GET /api/v1/materials/colors?material_type=PLA_BASIC` first

4. **Check JSON format:**
   - No trailing commas
   - All strings in quotes
   - Numbers without quotes

5. **Check backend logs:**
   - Look at the backend PowerShell window for detailed error messages

