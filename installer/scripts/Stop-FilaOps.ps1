# Stop-FilaOps.ps1
# Stops FilaOps containers

param(
    [switch]$Silent,
    [switch]$RemoveVolumes  # Dangerous - removes all data!
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir = Split-Path -Parent $ScriptDir

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Stopping FilaOps..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    Push-Location $AppDir
    
    if ($RemoveVolumes) {
        Write-Host "WARNING: Removing all data volumes!" -ForegroundColor Red
        docker-compose down -v
    } else {
        docker-compose down
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "   FilaOps stopped successfully" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your data is preserved in Docker volumes." -ForegroundColor Gray
        Write-Host "Run Start-FilaOps to start again." -ForegroundColor Gray
        Write-Host ""
    } else {
        throw "docker-compose down failed"
    }
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to stop FilaOps" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    exit 1
} finally {
    Pop-Location
}

if (-not $Silent) {
    Write-Host "Press any key to close this window..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
