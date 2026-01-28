# FilaOps Production Sync Script
# Syncs ONLY runtime-essential files from core to production
# Excludes: docs, tests, CI/CD, dev tools, reports
#
# Usage: .\sync-to-prod.ps1 [-DryRun] [-Force]

param(
    [switch]$DryRun,
    [switch]$Force
)

# === CONFIGURATION ===
$CoreRepo = "C:\repos\filaops"
$ProdEnv = "C:\BLB3D_Production"

# Files/folders to NEVER overwrite (Pro-specific or local config)
$PreservePatterns = @(
    ".env",
    ".env.local",
    "backend\.env",
    "frontend\.env",
    "uploads\*",
    "logs\*",
    "backend\app\pro\*",
    "backend\app\pro_services\*",
    "frontend\src\pro\*",
    "pro_features\*",
    "data\*",
    "*.db",
    ".last-sync",
    ".pro-manifest"
)

# Files/folders to EXCLUDE from sync entirely (dev-only, not needed in prod)
$ExcludePatterns = @(
    # Git and dev tools
    ".git\*",
    ".github\*",
    ".vscode\*",
    ".claude\*",
    ".ai-instructions\*",
    ".ruff_cache\*",
    ".pytest_cache\*",
    
    # Documentation (lives in GitHub)
    "docs\*",
    "*.md",
    
    # Tests (not needed in prod)
    "backend\tests\*",
    "frontend\tests\*",
    "frontend\test-results\*",
    "frontend\playwright-report\*",
    "*test*.py",
    "*test*.js",
    "*test*.jsx",
    "playwright.config.ts",
    
    # Dev/build tools
    "agents\*",
    "mock-api\*",
    "installer\*",
    "scripts\archive\*",
    "scripts\tools\*",
    
    # Build artifacts and caches
    "node_modules\*",
    "venv\*",
    "__pycache__\*",
    "*.pyc",
    "frontend\dist\*",
    
    # Config files not needed in prod
    ".coderabbit.yaml",
    ".gitignore",
    "docker-compose.test.yml",
    "CONTRIBUTING.md",
    "LICENSE",
    "PROPRIETARY.md",
    "CHANGELOG.md",
    "CLAUDE.md"
)

function Test-ShouldPreserve {
    param([string]$RelativePath)
    foreach ($pattern in $PreservePatterns) {
        if ($RelativePath -like $pattern) { return $true }
        if ($RelativePath -like "*\$pattern") { return $true }
    }
    return $false
}

function Test-ShouldExclude {
    param([string]$RelativePath)
    
    # Check each exclude pattern
    foreach ($pattern in $ExcludePatterns) {
        if ($RelativePath -like $pattern) { return $true }
        if ($RelativePath -like "*\$pattern") { return $true }
    }
    
    # Also exclude any .md files (docs)
    if ($RelativePath -like "*.md") { return $true }
    
    return $false
}

# === MAIN ===

Write-Host "============================================"
Write-Host "   FilaOps Production Sync (Lean Mode)     "
Write-Host "============================================"
Write-Host ""

if (-not (Test-Path $CoreRepo)) {
    Write-Host "ERROR: Core repo not found: $CoreRepo" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ProdEnv)) {
    Write-Host "Production folder not found: $ProdEnv" -ForegroundColor Yellow
    Write-Host "Creating it..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $ProdEnv -Force | Out-Null
}

Write-Host "Source: $CoreRepo"
Write-Host "Target: $ProdEnv"
Write-Host ""
Write-Host "Mode: LEAN (runtime files only, no docs/tests)" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN MODE - No files will be changed]" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Scanning files..."

# Get all files from core
$coreFiles = Get-ChildItem -Path $CoreRepo -Recurse -File -ErrorAction SilentlyContinue

$newCount = 0
$updateCount = 0
$preserveCount = 0
$unchangedCount = 0
$excludeCount = 0

foreach ($file in $coreFiles) {
    $relativePath = $file.FullName.Substring($CoreRepo.Length + 1)
    $targetPath = Join-Path $ProdEnv $relativePath
    
    # Should we exclude this file entirely?
    if (Test-ShouldExclude $relativePath) {
        $excludeCount++
        continue
    }
    
    # Should we preserve existing file in prod?
    if (Test-ShouldPreserve $relativePath) {
        if (Test-Path $targetPath) {
            $preserveCount++
            if ($DryRun) {
                Write-Host "  [KEEP] $relativePath" -ForegroundColor Yellow
            }
        }
        continue
    }
    
    # Does target exist?
    if (-not (Test-Path $targetPath)) {
        $newCount++
        if ($DryRun) {
            Write-Host "  [NEW]  $relativePath" -ForegroundColor Blue
        } else {
            $targetDir = Split-Path $targetPath -Parent
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            Copy-Item $file.FullName $targetPath -Force
        }
    }
    else {
        # Compare hashes
        $srcHash = (Get-FileHash $file.FullName -Algorithm MD5).Hash
        $tgtHash = (Get-FileHash $targetPath -Algorithm MD5).Hash
        
        if ($srcHash -ne $tgtHash) {
            $updateCount++
            if ($DryRun) {
                Write-Host "  [UPD]  $relativePath" -ForegroundColor Green
            } else {
                Copy-Item $file.FullName $targetPath -Force
            }
        }
        else {
            $unchangedCount++
        }
    }
}

Write-Host ""
Write-Host "============================================"
Write-Host "SUMMARY"
Write-Host "============================================"
Write-Host "  New files:     $newCount" -ForegroundColor Blue
Write-Host "  Updated:       $updateCount" -ForegroundColor Green
Write-Host "  Preserved:     $preserveCount" -ForegroundColor Yellow
Write-Host "  Unchanged:     $unchangedCount" -ForegroundColor Gray
Write-Host "  Excluded:      $excludeCount (docs, tests, dev tools)" -ForegroundColor DarkGray
Write-Host ""

if ($DryRun) {
    Write-Host "This was a dry run. Use without -DryRun to apply." -ForegroundColor Cyan
} else {
    # Write sync log
    $syncLog = Join-Path $ProdEnv ".last-sync"
    "synced=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nnew=$newCount`nupdated=$updateCount`nexcluded=$excludeCount" | Out-File $syncLog -Encoding UTF8
    Write-Host "Sync complete!" -ForegroundColor Green
}
