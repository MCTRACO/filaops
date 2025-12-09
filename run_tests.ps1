# Quick test runner - checks if server is running first
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "FilaOps Material Endpoint Test Runner" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Check if server is running
Write-Host "`nChecking if server is running..." -ForegroundColor Yellow
$serverRunning = $false

# Try multiple endpoints
$endpoints = @(
    "http://localhost:8000/health",
    "http://localhost:8000/docs",
    "http://localhost:8000"
)

foreach ($endpoint in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri $endpoint -TimeoutSec 3 -ErrorAction Stop -UseBasicParsing
        Write-Host "[OK] Server is running (checked: $endpoint)" -ForegroundColor Green
        $serverRunning = $true
        break
    }
    catch {
        # Continue to next endpoint
        continue
    }
}

if (-not $serverRunning) {
    Write-Host "[WARNING] Could not verify server, but continuing anyway..." -ForegroundColor Yellow
    Write-Host "The test script will try to connect directly." -ForegroundColor Yellow
}

# Run the test script
Write-Host "`nRunning automated tests...`n" -ForegroundColor Yellow
python test_material_endpoint.py

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] Tests completed!" -ForegroundColor Green
}
else {
    Write-Host "`n[ERROR] Tests failed!" -ForegroundColor Red
}
