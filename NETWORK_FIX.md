# Network Connectivity Fix

## Issue
"Failed to fetch" error when accessing `/admin/orders/48` from the frontend.

## Root Cause
IPv6/IPv4 resolution mismatch:
- Frontend is on IPv6: `[::1]:5173`
- Backend is on IPv4: `0.0.0.0:8000`
- Browser resolves `localhost:8000` to IPv6 `[::1]:8000` which backend doesn't listen on

## Fix Applied

1. **Updated OrderDetail.jsx** to use `127.0.0.1:8000` instead of `localhost:8000`
2. **Created shared API config** at `frontend/src/config/api.js`
3. **Updated CORS settings** to allow both `localhost:5173` and `127.0.0.1:5173`

## Testing

1. **Refresh the browser** (hard refresh: Ctrl+Shift+R)
2. **Check browser console** - should now connect successfully
3. **If still failing**, check:
   - Backend is running: `curl http://127.0.0.1:8000/health`
   - Frontend can reach backend: Open DevTools → Network tab → Check request

## Manual Test

In browser console:
```javascript
// Should work now
const token = localStorage.getItem("adminToken");
fetch("http://127.0.0.1:8000/api/v1/sales-orders/48", {
  headers: { Authorization: `Bearer ${token}` }
})
  .then(r => r.json())
  .then(console.log)
  .catch(console.error);
```

## Next Steps

If issue persists:
1. Check if backend is actually listening on IPv4: `netstat -ano | findstr :8000`
2. Try accessing backend directly: `http://127.0.0.1:8000/docs`
3. Check browser console Network tab for actual error details

