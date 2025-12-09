# OrderDetail Debug Guide

## Error: "Failed to fetch"

This is a generic network error. Check the following:

### 1. Check Browser Console
Open DevTools (F12) → Console tab and look for:
- Detailed error messages (now logged with `console.error`)
- Network tab → Check if request is being made
- Status code (404, 401, 500, etc.)

### 2. Check Backend Server
- Is the backend running? `http://localhost:8000`
- Check backend logs for errors
- Try accessing: `http://localhost:8000/docs` (API docs)

### 3. Check Authentication
- Is the user logged in?
- Check `localStorage.getItem("adminToken")` in browser console
- Token might be expired - try logging out and back in

### 4. Test Order Endpoint Directly
```bash
# In PowerShell (replace TOKEN with actual token)
$token = "YOUR_TOKEN_HERE"
Invoke-WebRequest -Uri "http://localhost:8000/api/v1/sales-orders/48" -Headers @{Authorization="Bearer $token"}
```

### 5. Check CORS
- If backend is on different port, CORS might be blocking
- Check backend CORS settings in `backend/app/main.py`

### 6. Enhanced Error Logging
The frontend now logs:
- `console.log("Exploding BOM for product X, quantity Y")`
- `console.log("MRP requirements response:", data)`
- `console.error("Failed to fetch order:", err)` with full error details
- `console.warn("MRP requirements failed (status):", errorText)`

### 7. Test Order Details
**Order ID:** 48  
**Order Number:** SO-2025-022  
**Product ID:** 525 (TEST-001)  
**BOM ID:** 64

**Expected Behavior:**
1. Order loads with header info
2. Line items show: TEST-001 x 10
3. Material Requirements section shows: COMP-KEYRING - 40 EA needed
4. Capacity Requirements: (none - no routing)

### 8. Common Issues

**Issue:** 401 Unauthorized
- **Fix:** Token expired or invalid - re-login

**Issue:** 404 Not Found
- **Fix:** Check order ID exists: `SELECT id FROM sales_orders WHERE id = 48`

**Issue:** 500 Internal Server Error
- **Fix:** Check backend logs for SQL errors or exceptions

**Issue:** CORS error
- **Fix:** Check backend CORS middleware allows frontend origin

### 9. Manual API Test
```javascript
// In browser console on http://localhost:5173
const token = localStorage.getItem("adminToken");
fetch("http://localhost:8000/api/v1/sales-orders/48", {
  headers: { Authorization: `Bearer ${token}` }
})
  .then(r => r.json())
  .then(console.log)
  .catch(console.error);
```

---

**Next Steps:**
1. Check browser console for detailed error
2. Check backend logs
3. Verify authentication token
4. Test API endpoint directly

