# FilaOps - Open Source Core (v3.0.0)

## ⚠️ STOP - READ BEFORE ANY CHANGES

This is the **OPEN SOURCE Community edition**. It goes to GitHub.

### DO NOT Add Here

- ❌ B2B Portal backend/endpoints
- ❌ Price levels / Customer tiers
- ❌ Catalog access control
- ❌ Quote engine / Public quoter API
- ❌ Integrations (QuickBooks, Shopify, marketplaces)
- ❌ Any feature that requires subscription/payment

**Those are PRO features → `C:\BLB3D_Production`**

### DO Add Here

- ✅ Core ERP (inventory, MRP, production orders, sales orders)
- ✅ BOM management
- ✅ Traceability (lots, serials)
- ✅ UOM system and cost calculations
- ✅ Basic reporting
- ✅ Bug fixes to existing Community features

## Repository Map

| Repo | Purpose | Public? |
|------|---------|---------|
| `C:\repos\filaops` | **THIS REPO** - Open source core | ✅ GitHub |
| `C:\repos\filaops-portal` | Portal frontend (Next.js) | ❌ Private |
| `C:\BLB3D_Production` | PRO backend development | ❌ Private |

## Tech Stack

- Backend: FastAPI + SQLAlchemy + PostgreSQL
- Frontend: React + Vite + Tailwind
- See `.claude/skills/` for detailed patterns

## ⚠️ Database Safety Rule - READ FIRST

**BEFORE any database operation (migrations, queries, schema changes):**

1. Read `backend/.env` to confirm `DATABASE_URL` or `DB_NAME`
2. Verify which DB the MCP postgres tool is connected to: `SELECT current_database();`
3. State explicitly: "Working against database `X`"
4. If there's ANY mismatch, **STOP and clarify with Brandan**

**Databases:**

| Database | Purpose | Used By |
|----------|---------|---------|
| `filaops` | **Dev/open-source testing** | `C:\repos\filaops` (this repo) |
| `filaops_prod` | Production + PRO dev | `C:\BLB3D_Production` |
| `filaops_test` | Automated tests | pytest |
| `filaops_cortex` | Cortex agent memory | `C:\repos\filaops-cortex` |

**This repo uses `filaops` - never run migrations against `filaops_prod` from here!**

## UOM Safety

Costs stored as $/KG, inventory tracked in grams. Single source of truth: `backend/app/core/uom_config.py`

**Never hardcode UOM conversion factors elsewhere.**

## Quick Start

```powershell
# Backend
cd backend && .\venv\Scripts\Activate && uvicorn app.main:app --reload

# Frontend
cd frontend && npm run dev
```

## v3.0.0 Changes

This version represents the first clean Core/PRO separation:
- Removed B2B Portal features
- Removed Catalog/Price Levels
- Removed Shopify integration
- Removed Amazon import
- Removed License management
- Removed AI Invoice Parser
- Removed PRO accounting features (Schedule C, entity members)
- Kept: 37 Core features, MQTT, basic GL
