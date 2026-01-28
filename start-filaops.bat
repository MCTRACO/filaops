@echo off
echo ========================================
echo   FilaOps Production Server
echo ========================================
echo.

echo Stopping existing services...
taskkill /IM caddy.exe /F 2>nul
taskkill /IM python.exe /F 2>nul
taskkill /IM node.exe /F 2>nul

cd /d C:\BLB3D_Production

echo Starting Caddy (reverse proxy)...
start /min "" cmd /c "cd /d C:\BLB3D_Production && C:\BLB3D_Production\caddy.exe run"

echo Starting Backend (port 10000)...
start "" cmd /k "cd /d C:\BLB3D_Production\backend && C:\BLB3D_Production\backend\venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 10000"

echo Starting Frontend (port 5173)...
start /min "" cmd /c "cd /d C:\BLB3D_Production\frontend && npm run dev"

echo.
echo Waiting for services to start...
timeout /t 10 >nul

echo Opening FilaOps in browser...
start "" "https://filaops.blb3d.local/admin/login"
start "" "http://localhost:3000"

echo.
echo ========================================
echo   FilaOps is running!
echo   Admin: https://filaops.blb3d.local/admin/login
echo   B2B Portal: http://localhost:3000
echo ========================================
echo.
echo Press any key to STOP all services...
pause >nul

echo Stopping services...
taskkill /IM caddy.exe /F
taskkill /IM python.exe /F
taskkill /IM node.exe /F
echo Done.
