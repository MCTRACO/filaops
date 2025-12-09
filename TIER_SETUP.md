# Setting Up Tier for Testing

## Issue: Tier Still Shows "Open"

The tier is read from the `TIER` environment variable in `backend/.env`. If it's still showing "open", follow these steps:

## Solution

1. **Check `.env` file exists** in `backend/.env`
   - Should contain: `TIER=pro` (or `TIER=enterprise`)

2. **Restart the backend server**
   - Settings are cached, so you MUST restart after changing `.env`
   - Stop the server (Ctrl+C)
   - Start it again: `.\start-backend.ps1` or `python -m uvicorn app.main:app --reload`

3. **Clear browser cache** (optional but recommended)
   - Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
   - Or clear localStorage: Open DevTools → Application → Local Storage → Clear

4. **Verify it's working**
   - Visit `/admin/analytics` - should show analytics dashboard (not the Pro announcement)
   - Check browser console for any errors
   - Check Network tab - `/api/v1/features/current` should return `{"tier": "pro", ...}`

## Testing Different Tiers

### Open Tier (Default)
```env
TIER=open
```
- Analytics shows Pro announcement
- All Pro features gated

### Pro Tier
```env
TIER=pro
```
- Analytics dashboard accessible
- Pro features available

### Enterprise Tier
```env
TIER=enterprise
```
- All Pro features + Enterprise features
- ML time estimation, printer fleet, etc.

## Troubleshooting

### Still showing "open" after restart?
1. Check `.env` file is in `backend/` directory (not root)
2. Check `.env` file has `TIER=pro` (no quotes, no spaces)
3. Make sure backend server was fully stopped before restarting
4. Check backend logs for any errors loading settings

### Frontend not updating?
1. Hard refresh browser (Ctrl+Shift+R)
2. Check browser console for errors
3. Check Network tab - is `/api/v1/features/current` returning correct tier?
4. Clear browser localStorage and refresh

### API returning 402 Payment Required?
- This means the tier check is working!
- The endpoint requires Pro tier
- Set `TIER=pro` in `.env` and restart backend

