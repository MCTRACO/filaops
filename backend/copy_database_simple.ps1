# PowerShell script to copy BLB3D_ERP to FilaOps
# Run from backend directory: .\copy_database_simple.ps1

$server = "localhost\SQLEXPRESS"
$sourceDb = "BLB3D_ERP"
$targetDb = "FilaOps"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Copying Database: $sourceDb -> $targetDb" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Run the SQL script
$sqlScript = Join-Path $PSScriptRoot "..\scripts\copy_database_to_filaops.sql"

Write-Host "`nExecuting SQL script..." -ForegroundColor Yellow
sqlcmd -S $server -i $sqlScript

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Database copy complete!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. Update your .env file: DB_NAME=FilaOps" -ForegroundColor White
    Write-Host "  2. Run: python migrate_material_inventory_to_products.py" -ForegroundColor White
} else {
    Write-Host "`n❌ Database copy failed!" -ForegroundColor Red
    exit 1
}

