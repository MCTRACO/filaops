# ItemForm Fix - PATCH Method

**Date:** 2025-01-15  
**Status:** ✅ **FIXED**

---

## Problem

ItemForm was using `PUT` method to update items, but the API endpoint uses `PATCH`:

```
PUT http://localhost:8000/api/v1/items/331 405 (Method Not Allowed)
```

---

## Solution

Changed ItemForm to use `PATCH` instead of `PUT`:

```jsx
// Before
const method = editingItem ? "PUT" : "POST";

// After
const method = editingItem ? "PATCH" : "POST";
```

---

## API Endpoint

The correct endpoint is:
- **Update:** `PATCH /api/v1/items/{item_id}`
- **Create:** `POST /api/v1/items`

---

## Testing

1. Go to Admin → Items
2. Click "Edit" on any item
3. Change procurement_type from "Buy" to "Make"
4. Click "Update Item"
5. Should now work without 405 error

---

**Fixed:** ItemForm now uses PATCH method for updates ✅

