@echo off
echo ========================================
echo   Installing FilaOps as Windows Services
echo ========================================
echo.
echo This requires Administrator privileges.
echo.

:: Create Caddy startup task
echo Creating Caddy service task...
schtasks /create /tn "FilaOps-Caddy" /tr "c:\tools\caddy.exe run --config c:\BLB3D_Production\Caddyfile" /sc onstart /ru SYSTEM /rl highest /f
if %errorlevel% neq 0 (
    echo Failed to create Caddy task. Try running as Administrator.
) else (
    echo Caddy task created successfully.
)

echo.

:: Create FilaOps Backend startup task
echo Creating FilaOps Backend service task...
schtasks /create /tn "FilaOps-Backend" /tr "c:\BLB3D_Production\backend\venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --app-dir c:\BLB3D_Production\backend" /sc onstart /ru SYSTEM /rl highest /f
if %errorlevel% neq 0 (
    echo Failed to create Backend task. Try running as Administrator.
) else (
    echo Backend task created successfully.
)

echo.
echo ========================================
echo   Starting services now...
echo ========================================
echo.

:: Start the tasks now
schtasks /run /tn "FilaOps-Caddy"
schtasks /run /tn "FilaOps-Backend"

echo.
echo Done! FilaOps will now start automatically on boot.
echo.
pause
