# Network Debugging Steps

## Current Status
- Backend is running and reachable on `127.0.0.1:8000` ✅
- Frontend is using `127.0.0.1:8000` in API_URL ✅
- Still getting "Failed to fetch" error ❌

## Debug Steps

### 1. Check Browser Console
After refreshing, you should see:
```
OrderDetail mounted - API_URL: http://127.0.0.1:8000
Order ID: 48
Token present: true
Full URL will be: http://127.0.0.1:8000/api/v1/sales-orders/48
Fetching order from: http://127.0.0.1:8000/api/v1/sales-orders/48
```

### 2. Check Network Tab
1. Open DevTools (F12)
2. Go to Network tab
3. Refresh the page
4. Look for the request to `/api/v1/sales-orders/48`
5. Check:
   - Status code
   - Request URL (should be `http://127.0.0.1:8000/...`)
   - Headers (Authorization should be present)
   - Response (if any)

### 3. Test in Browser Console
```javascript
// Test 1: Check API_URL
import { API_URL } from './config/api.js';
console.log(API_URL); // Should be http://127.0.0.1:8000

// Test 2: Test fetch directly
const token = localStorage.getItem("adminToken");
fetch("http://127.0.0.1:8000/api/v1/sales-orders/48", {
  headers: { Authorization: `Bearer ${token}` }
})
  .then(r => {
    console.log("Status:", r.status);
    return r.json();
  })
  .then(console.log)
  .catch(err => {
    console.error("Fetch error:", err);
    console.error("Error name:", err.name);
    console.error("Error message:", err.message);
  });
```

### 4. Common Issues

**Issue: CORS Preflight Failing**
- Check Network tab for OPTIONS request
- Should return 200 with CORS headers
- If 404 or error, CORS middleware not working

**Issue: Mixed Content**
- If frontend is HTTPS, backend must be HTTPS
- Not applicable here (both HTTP)

**Issue: Browser Extension Blocking**
- Try incognito mode
- Disable browser extensions

**Issue: Firewall/Antivirus**
- Check if Windows Firewall is blocking
- Check antivirus network protection

### 5. Quick Fix: Try Direct IP
If still failing, try accessing frontend via `127.0.0.1:5173` instead of `localhost:5173`

### 6. Backend Logs
Check backend console for:
- Incoming requests
- CORS errors
- Authentication errors

## Expected Behavior
1. Browser makes OPTIONS request (CORS preflight)
2. Backend responds with 200 and CORS headers
3. Browser makes GET request with Authorization header
4. Backend responds with order data or 401 if token invalid

## Next Steps
1. Check browser console for the debug logs
2. Check Network tab for actual request/response
3. Share the Network tab details if still failing

