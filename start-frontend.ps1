# FilaOps Frontend Startup Script
# Starts only the frontend dev server

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "FilaOps Frontend - Starting" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "frontend" -PathType Container)) {
    Write-Host "[ERROR] Please run this script from the project root directory" -ForegroundColor Red
    exit 1
}

# Start frontend
Write-Host "`n[FRONTEND] Starting Vite dev server..." -ForegroundColor Yellow
Write-Host "Frontend will be available at: http://localhost:5173" -ForegroundColor White
Write-Host "`nPress Ctrl+C to stop the server`n" -ForegroundColor Yellow

Set-Location frontend
npm run dev

