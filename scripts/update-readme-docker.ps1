# Update README.md with Docker hero section
# Run: .\scripts\update-readme-docker.ps1

$readmePath = "README.md"

if (-not (Test-Path $readmePath)) {
    Write-Host "❌ README.md not found!" -ForegroundColor Red
    exit 1
}

$readmeContent = Get-Content $readmePath -Raw

# New Docker hero section
$newQuickStart = @"
## 🚀 Quick Start (Docker - 5 Minutes)

**No coding required!** Perfect for print farm owners who want professional ERP functionality without the complexity.

``````bash
# 1. Clone the repo
git clone https://github.com/Blb3D/filaops.git
cd filaops

# 2. Start everything (one command!)
docker-compose up -d

# 3. Open your browser
# http://localhost:5173
``````

**That's it!** Everything is pre-configured:
- ✅ SQL Server database (auto-initialized)
- ✅ Backend API (FastAPI)
- ✅ Frontend UI (React)
- ✅ All dependencies included

**Default login:** admin@filaops.local / admin123

📖 **[Full Installation Guide](INSTALL.md)** - Step-by-step for Windows/Mac/Linux

> **Why Docker?** Most ERP systems require hours of setup, database configuration, and dependency management. FilaOps runs in containers - everything just works. Perfect for print farm owners who want to focus on their business, not IT infrastructure.
"@

# Replace the Quick Start section (from "## 🚀 Quick Start" to "---")
$pattern = '(?s)## 🚀 Quick Start.*?---'
if ($readmeContent -match $pattern) {
    $readmeContent = $readmeContent -replace $pattern, "$newQuickStart`n`n---"
    Set-Content -Path $readmePath -Value $readmeContent -NoNewline
    Write-Host "✅ README.md updated with Docker hero section!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Could not find Quick Start section to replace" -ForegroundColor Yellow
    Write-Host "   Manual update may be required" -ForegroundColor Yellow
}

