# Open-FilaOps.ps1
# Opens FilaOps in browser, starting containers if needed

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Quick check if already running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5173" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
    # Already running, just open browser
    Start-Process "http://localhost:5173"
    exit 0
} catch {
    # Not running, start it
    & "$ScriptDir\Start-FilaOps.ps1"
}
