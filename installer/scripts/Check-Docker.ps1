# Check-Docker.ps1
# Checks if Docker Desktop is installed and running

$ErrorActionPreference = "SilentlyContinue"

function Test-DockerInstalled {
    $docker = Get-Command docker -ErrorAction SilentlyContinue
    return $null -ne $docker
}

function Test-DockerRunning {
    $result = docker info 2>&1
    return $LASTEXITCODE -eq 0
}

function Show-DockerNotice {
    param([string]$Message, [string]$Title = "FilaOps - Docker Required")
    
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
}

# Main check
if (-not (Test-DockerInstalled)) {
    Show-DockerNotice @"
Docker Desktop is not installed.

FilaOps requires Docker Desktop to run.

Please download and install Docker Desktop from:
https://docker.com/products/docker-desktop

After installing Docker Desktop:
1. Start Docker Desktop
2. Wait for it to fully start (whale icon in system tray)
3. Then launch FilaOps
"@
    
    # Open Docker download page
    Start-Process "https://docker.com/products/docker-desktop"
    exit 1
}

if (-not (Test-DockerRunning)) {
    Show-DockerNotice @"
Docker Desktop is installed but not running.

Please start Docker Desktop:
1. Open Docker Desktop from your Start Menu
2. Wait for it to fully start (whale icon in system tray)
3. Then launch FilaOps

If Docker Desktop won't start, try restarting your computer.
"@
    
    # Try to start Docker Desktop
    $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Start-Process $dockerPath
    }
    exit 1
}

Write-Host "Docker is installed and running." -ForegroundColor Green
exit 0
