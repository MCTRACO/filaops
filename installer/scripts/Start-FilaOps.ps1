# Start-FilaOps.ps1
# Starts FilaOps containers and opens browser

param(
    [switch]$Silent,
    [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir = Split-Path -Parent $ScriptDir

# Check Docker first
& "$ScriptDir\Check-Docker.ps1"
if ($LASTEXITCODE -ne 0) {
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Starting FilaOps..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    Push-Location $AppDir
    
    # Pull latest images (in case of updates)
    Write-Host "Checking for container updates..." -ForegroundColor Yellow
    docker-compose pull 2>&1 | Out-Null
    
    # Start containers
    Write-Host "Starting containers..." -ForegroundColor Yellow
    docker-compose up -d --build
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start containers"
    }
    
    # Wait for services to be healthy
    Write-Host ""
    Write-Host "Waiting for services to start..." -ForegroundColor Yellow
    
    $maxAttempts = 30
    $attempt = 0
    $ready = $false
    
    while ($attempt -lt $maxAttempts -and -not $ready) {
        Start-Sleep -Seconds 2
        $attempt++
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8000/api/v1/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                $ready = $true
            }
        } catch {
            Write-Host "  Attempt $attempt/$maxAttempts - waiting..." -ForegroundColor Gray
        }
    }
    
    if ($ready) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "   FilaOps is running!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "   Open your browser to:" -ForegroundColor White
        Write-Host "   http://localhost:5173" -ForegroundColor Cyan
        Write-Host ""
        
        if (-not $NoBrowser) {
            Start-Process "http://localhost:5173"
        }
    } else {
        Write-Host ""
        Write-Host "Services started but may still be initializing." -ForegroundColor Yellow
        Write-Host "Try opening http://localhost:5173 in a few moments." -ForegroundColor Yellow
        
        if (-not $NoBrowser) {
            Start-Process "http://localhost:5173"
        }
    }
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to start FilaOps" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure Docker Desktop is running" -ForegroundColor White
    Write-Host "2. Check Docker Desktop has enough resources (4GB+ RAM recommended)" -ForegroundColor White
    Write-Host "3. Try: docker-compose logs" -ForegroundColor White
    Write-Host ""
    exit 1
} finally {
    Pop-Location
}

if (-not $Silent) {
    Write-Host "Press any key to close this window..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
