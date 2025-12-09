# Complete viral launch script
# Updates README, adds topics, creates release
# Run: .\scripts\viral-launch.ps1

param(
    [switch]$SkipRelease = $false,
    [switch]$DraftRelease = $false
)

Write-Host ""
Write-Host "🚀 FilaOps Viral Launch Script" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$errors = @()

# Step 1: Update README
Write-Host "Step 1: Updating README.md..." -ForegroundColor Yellow
try {
    & ".\scripts\update-readme-docker.ps1"
    if ($LASTEXITCODE -ne 0) {
        $errors += "README update"
    }
} catch {
    $errors += "README update (error: $_)"
}
Write-Host ""

# Step 2: Add GitHub topics
Write-Host "Step 2: Adding GitHub topics..." -ForegroundColor Yellow
try {
    & ".\scripts\add-github-topics.ps1"
    if ($LASTEXITCODE -ne 0) {
        $errors += "GitHub topics"
    }
} catch {
    $errors += "GitHub topics (error: $_)"
}
Write-Host ""

# Step 3: Create release (optional)
if (-not $SkipRelease) {
    Write-Host "Step 3: Creating GitHub release..." -ForegroundColor Yellow
    try {
        if ($DraftRelease) {
            & ".\scripts\create-release.ps1" -Draft
        } else {
            & ".\scripts\create-release.ps1"
        }
        if ($LASTEXITCODE -ne 0) {
            $errors += "GitHub release"
        }
    } catch {
        $errors += "GitHub release (error: $_)"
    }
    Write-Host ""
} else {
    Write-Host "Step 3: Skipping release creation (--SkipRelease)" -ForegroundColor Gray
    Write-Host ""
}

# Summary
Write-Host "================================" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "✅ Viral launch script complete!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Completed with some issues:" -ForegroundColor Yellow
    foreach ($error in $errors) {
        Write-Host "   - $error" -ForegroundColor Yellow
    }
}
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review changes: git diff README.md" -ForegroundColor White
Write-Host "2. Commit changes: git add README.md && git commit -m 'docs: Update README with Docker hero section'" -ForegroundColor White
Write-Host "3. Push: git push origin main" -ForegroundColor White
Write-Host "4. Post on Reddit: r/3Dprinting, r/selfhosted" -ForegroundColor White
Write-Host "5. Post on Twitter/X" -ForegroundColor White
Write-Host ""

