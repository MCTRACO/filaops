# Update-FilaOps.ps1
# Updates FilaOps to the latest version

param(
    [switch]$Silent,
    [switch]$SkipBackup,
    [string]$TargetVersion  # e.g., "v2.1.0" - defaults to latest
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir = Split-Path -Parent $ScriptDir
$BackupDir = Join-Path $AppDir "backups"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host ">> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "   ✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "   ⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "   ✗ $Message" -ForegroundColor Red
}

function Get-CurrentVersion {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/system/version" -TimeoutSec 5
        return $response.version
    } catch {
        # Try reading from file if service not running
        $versionFile = Join-Path $AppDir "backend\app\version.py"
        if (Test-Path $versionFile) {
            $content = Get-Content $versionFile -Raw
            if ($content -match '__version__\s*=\s*"([^"]+)"') {
                return $matches[1]
            }
        }
        return "unknown"
    }
}

function Get-LatestVersion {
    try {
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/Blb3D/filaops/releases" -TimeoutSec 10
        $latest = $releases | Where-Object { -not $_.prerelease } | Select-Object -First 1
        return @{
            Version = $latest.tag_name
            Url = $latest.html_url
            Body = $latest.body
        }
    } catch {
        return $null
    }
}

function Backup-Database {
    Write-Step "Creating database backup..."
    
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
    
    $backupFile = Join-Path $BackupDir "filaops_backup_$Timestamp.sql"
    
    try {
        # Get the postgres container name
        $containerName = docker-compose ps -q postgres 2>$null
        if ($containerName) {
            docker exec $containerName pg_dump -U filaops filaops > $backupFile 2>$null
            
            if (Test-Path $backupFile) {
                $size = (Get-Item $backupFile).Length / 1KB
                Write-Success "Backup created: $backupFile ($([math]::Round($size, 1)) KB)"
                return $backupFile
            }
        }
        Write-Warning "Could not create database backup (containers may not be running)"
        return $null
    } catch {
        Write-Warning "Backup failed: $($_.Exception.Message)"
        return $null
    }
}

function Update-Application {
    param([string]$Version)
    
    Write-Step "Downloading update..."
    
    Push-Location $AppDir
    
    try {
        # Stop containers first
        Write-Step "Stopping FilaOps..."
        docker-compose down 2>&1 | Out-Null
        Write-Success "Containers stopped"
        
        # Pull latest code
        Write-Step "Pulling latest code..."
        
        if ($Version) {
            git fetch --tags 2>&1 | Out-Null
            git checkout $Version 2>&1
        } else {
            git pull origin main 2>&1
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Git pull failed"
        }
        Write-Success "Code updated"
        
        # Rebuild and start
        Write-Step "Rebuilding containers..."
        docker-compose build --no-cache 2>&1 | Out-Null
        Write-Success "Containers rebuilt"
        
        Write-Step "Starting FilaOps..."
        docker-compose up -d 2>&1 | Out-Null
        
        # Wait for healthy
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
                # Still starting...
            }
        }
        
        if ($ready) {
            Write-Success "FilaOps is running"
            return $true
        } else {
            Write-Warning "Services started but may still be initializing"
            return $true
        }
        
    } catch {
        Write-Error "Update failed: $($_.Exception.Message)"
        return $false
    } finally {
        Pop-Location
    }
}

# ============================================================================
# Main
# ============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   FilaOps Updater" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get current version
$currentVersion = Get-CurrentVersion
Write-Host ""
Write-Host "Current version: $currentVersion" -ForegroundColor White

# Get latest version
$latest = Get-LatestVersion
if ($null -eq $latest) {
    Write-Error "Could not check for updates. Please check your internet connection."
    exit 1
}

$targetVersion = if ($TargetVersion) { $TargetVersion } else { $latest.Version }

Write-Host "Target version:  $targetVersion" -ForegroundColor White

if ($currentVersion -eq $targetVersion.TrimStart('v')) {
    Write-Host ""
    Write-Host "You're already on the latest version!" -ForegroundColor Green
    exit 0
}

# Confirm update
if (-not $Silent) {
    Write-Host ""
    Write-Host "This will update FilaOps from $currentVersion to $targetVersion" -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Update cancelled." -ForegroundColor Gray
        exit 0
    }
}

# Backup
if (-not $SkipBackup) {
    $backupFile = Backup-Database
}

# Update
$success = Update-Application -Version $targetVersion

if ($success) {
    $newVersion = Get-CurrentVersion
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   Update complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Version: $newVersion" -ForegroundColor White
    Write-Host "   URL: http://localhost:5173" -ForegroundColor Cyan
    Write-Host ""
    
    if ($backupFile) {
        Write-Host "   Backup saved to:" -ForegroundColor Gray
        Write-Host "   $backupFile" -ForegroundColor Gray
        Write-Host ""
    }
    
    Start-Process "http://localhost:5173"
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "   Update failed" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    
    if ($backupFile) {
        Write-Host "Your backup is safe at:" -ForegroundColor Yellow
        Write-Host $backupFile -ForegroundColor White
        Write-Host ""
        Write-Host "To restore, run:" -ForegroundColor Yellow
        Write-Host "docker exec -i <postgres_container> psql -U filaops filaops < `"$backupFile`"" -ForegroundColor White
    }
    
    exit 1
}

if (-not $Silent) {
    Write-Host "Press any key to close..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
