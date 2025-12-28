# INFRA-003: Test Data Seeding API

## Status: COMPLETED

---

## Overview

**Goal:** Connect Playwright E2E tests to backend test data factories via REST API
**Outcome:** Frontend tests can call `await seedTestScenario('full-demand-chain')` to get real interconnected data

---

## What Was Done

### Created Files

1. **`backend/tests/factories.py`** - Model-aware factory functions
   - `create_test_user()` - Users with hashed passwords
   - `create_test_vendor()` - Vendors with lead times
   - `create_test_product()` - Products with pricing
   - `create_test_material()` - Raw materials (supply items)
   - `create_test_bom()` - BOMs with lines
   - `create_test_sales_order()` - Sales orders with lines
   - `create_test_production_order()` - Work orders linked to SOs
   - `create_test_purchase_order()` - POs with lines
   - `create_test_location()` - Inventory locations
   - `create_test_inventory()` - Inventory records
   - `reset_sequences()` - Reset sequence counters between tests

2. **`backend/tests/scenarios.py`** - Scenario seeding functions
   - `seed_empty()` - Just a test user for login
   - `seed_basic()` - Sample users, products, vendors, inventory
   - `seed_low_stock_with_allocations()` - For demand pegging tests
   - `seed_production_in_progress()` - Various WO statuses
   - `seed_full_demand_chain()` - Complete SO→WO→PO chain
   - `seed_so_with_blocking_issues()` - Fulfillment problems
   - `cleanup_test_data()` - Truncate test tables

3. **`backend/app/api/v1/endpoints/test.py`** - REST API endpoints
   - `GET /api/v1/test/scenarios` - List available scenarios
   - `POST /api/v1/test/seed` - Seed a scenario
   - `POST /api/v1/test/cleanup` - Remove all test data
   - `GET /api/v1/test/health` - Health check

4. **Updated `backend/app/api/v1/__init__.py`**
   - Added test router (disabled in production)

5. **Updated `frontend/tests/e2e/fixtures/test-utils.ts`**
   - `seedTestScenario()` - Now calls backend API
   - `cleanupTestData()` - Now calls backend API
   - `listScenarios()` - New function to list available scenarios
   - Added `SeedResponse` interface

---

## Available Scenarios

| Scenario | Description | Creates |
|----------|-------------|---------|
| `empty` | Clean slate for login testing | 1 admin user |
| `basic` | Sample data for general testing | Users, products, vendors, inventory |
| `low-stock-with-allocations` | Demand pegging tests | SO, WO, PO with shortages |
| `production-in-progress` | Production view tests | WOs in various statuses |
| `full-demand-chain` | Complete traceability testing | Customer→SO→WO→Materials→PO |
| `so-with-blocking-issues` | Fulfillment problem tests | Multi-line SO with blocked lines |

Aliases: `production-mto`, `production-with-shortage`, `full-production-context`

---

## Usage

### Frontend E2E Tests

```typescript
import { seedTestScenario, cleanupTestData } from './fixtures/test-utils';

test.describe('Demand Pegging', () => {
  test.beforeEach(async () => {
    await cleanupTestData();
    const result = await seedTestScenario('full-demand-chain');
    console.log('Created SO:', result.data.sales_order.order_number);
  });

  test('shows material shortages', async ({ page }) => {
    await login(page);
    await page.goto('/admin/inventory');
    // Test with real data...
  });
});
```

### Backend Unit Tests

```python
from tests.factories import create_test_user, create_test_product
from tests.scenarios import seed_scenario, cleanup_test_data

def test_something(db_session):
    # Use factories for granular control
    user = create_test_user(db_session, email="test@example.com")
    product = create_test_product(db_session, sku="TEST-001")

    # Or use scenarios for complete setups
    result = seed_scenario(db_session, "full-demand-chain")
    so_id = result["sales_order"]["id"]
```

### API Usage

```bash
# List scenarios
curl http://localhost:8000/api/v1/test/scenarios

# Seed a scenario
curl -X POST http://localhost:8000/api/v1/test/seed \
  -H "Content-Type: application/json" \
  -d '{"scenario": "full-demand-chain"}'

# Cleanup
curl -X POST http://localhost:8000/api/v1/test/cleanup
```

---

## Seed Response Format

```json
{
  "success": true,
  "scenario": "full-demand-chain",
  "data": {
    "users": {
      "admin": {"id": 1, "email": "admin@filaops.test"},
      "customer": {"id": 2, "email": "customer@acme.test", "company": "Acme Corporation"}
    },
    "vendor": {"id": 1, "code": "VND-001", "name": "Filament Depot"},
    "materials": {
      "pla": {"id": 11, "sku": "FIL-PLA-BLK", "on_hand": 10, "needed": 12.5},
      "hardware": {"id": 12, "sku": "HW-INSERT-M3", "on_hand": 150, "needed": 200}
    },
    "product": {"id": 13, "sku": "GADGET-PRO-01", "bom_id": 1},
    "sales_order": {"id": 1, "order_number": "SO-2025-0001"},
    "production_order": {"id": 1, "code": "WO-2025-0001"},
    "purchase_order": {"id": 1, "po_number": "PO-2025-0001"}
  }
}
```

---

## Security

**Production Guard:** Test endpoints are disabled when `ENVIRONMENT=production`
- Import guard in `__init__.py` checks env before importing router
- Endpoint guard via `require_test_mode()` dependency
- Returns 403 Forbidden if accessed in production

---

## Test Credentials

All scenarios create users with password: `TestPass123!`

| Email | Account Type | Created By |
|-------|--------------|------------|
| `admin@filaops.test` | admin | All scenarios |
| `customer@filaops.test` | customer | basic, production-* |
| `customer@acme.test` | customer | full-demand-chain |

---

## Verification

```bash
# Test factories import
cd backend
python -c "from tests.factories import create_test_user; print('OK')"

# Test scenarios import
python -c "from tests.scenarios import SCENARIOS; print(list(SCENARIOS.keys()))"

# Test API endpoint registration
python -c "from app.api.v1 import router; routes = [r.path for r in router.routes if '/test' in r.path]; print(routes)"

# Run backend tests
python -m pytest tests/ -v --tb=short
```

---

## Files Created/Modified

| File | Action |
|------|--------|
| `backend/tests/factories.py` | Created |
| `backend/tests/scenarios.py` | Created |
| `backend/app/api/v1/endpoints/test.py` | Created |
| `backend/app/api/v1/__init__.py` | Modified (added test router) |
| `frontend/tests/e2e/fixtures/test-utils.ts` | Modified (implemented API calls) |

---

## Next Steps

**UI-001: Component Testing Setup**
- Add Vitest + Testing Library for React component tests
- Create component test examples
- Integrate with E2E test data via `seedTestScenario()`
