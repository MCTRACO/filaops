# UI-102: Integrate ItemCard into Items Page

## Status: COMPLETED

---

## Overview

**Goal:** Wire the ItemCard component into the actual Items page so users can see demand context
**Outcome:** Users visiting `/admin/items` see ItemCards with allocations, availability, and shortage indicators

---

## What Was Implemented

### Files Modified

1. **`frontend/src/pages/admin/AdminItems.jsx`** - Main items page
   - Added `data-testid="items-page"` to main container
   - Added view toggle state (`table` | `cards`)
   - Added view toggle buttons (`data-testid="view-toggle-table"` and `data-testid="view-toggle-cards"`)
   - Added ItemCard grid view when `viewMode === "cards"`
   - ItemCards render with demand data from API-101 endpoint
   - Clicking an ItemCard navigates to item detail page

2. **`frontend/src/hooks/useItemDemand.js`** - Fixed token key
   - Changed `localStorage.getItem('token')` to `localStorage.getItem('adminToken')`
   - Fixed for both `useItemDemand` and `useMultipleItemDemands` functions

### Test Results

All 7 demand-pegging E2E tests pass:
- `user can trace shortage from item to customer` ✅
- `item card displays quantities correctly` ✅
- `shortage item shows warning indicator` ✅
- `item details link navigates correctly` ✅
- `demand-summary endpoint returns data` ✅
- `demand-summary shows allocations for material` ✅

---

## Why This Is Critical

**Current State:**
- ✅ API-101 returns demand data
- ✅ ItemCard component built
- ✅ E2E tests pass (at API level)
- ❌ **Users can't see any of this** - Items page still shows old display

**After UI-102:**
- Users see color-coded stock status on every item
- Users see allocations and incoming supply
- Users can trace shortages to consuming orders
- The redesign actually delivers value

---

## Discovery First

Before implementing, VS Code Claude must:

1. **Find the Items page:**
   ```bash
   # Search for items page
   find frontend/src -name "*item*" -type f
   grep -r "items" frontend/src/pages --include="*.jsx" --include="*.tsx"
   ```

2. **Understand current structure:**
   - What component renders the items list?
   - How is data currently fetched?
   - What props/state exists?

3. **Check routing:**
   ```bash
   grep -r "/admin/items" frontend/src
   ```

---

## Expected Page Locations (Verify!)

Likely locations based on FilaOps structure:
```
frontend/src/pages/admin/items/
frontend/src/pages/admin/inventory/
frontend/src/pages/Items.jsx
frontend/src/pages/Inventory.jsx
```

---

## Step-by-Step Execution

---

### Step 1 of 6: Discover Current Implementation
**Agent:** Frontend Agent
**Time:** 15 minutes
**Directory:** `frontend/src/`

**Instruction to Agent:**
```
Find the current Items/Inventory page implementation.

1. Search for the route handler for /admin/items
2. Find the component that renders the items list
3. Document:
   - File path
   - Current data fetching approach
   - Current item display component/structure
   - Any existing item card component
```

**Expected Discovery Output:**
```
Items Page Location: frontend/src/pages/admin/items/index.jsx
Current Display: Table with columns [SKU, Name, Type, Qty, Actions]
Data Fetching: useItems() hook or direct fetch in useEffect
Existing Card: None / SimpleItemRow component
```

**Commit:** None (discovery only)

---

### Step 2 of 6: Create Items Page Wrapper/Enhancement
**Agent:** Frontend Agent
**Time:** 30 minutes
**Directory:** `frontend/src/pages/admin/`

**Instruction to Agent:**
```
Modify the Items page to use ItemCard instead of current display.

Option A: If page uses a table
- Add a "Card View" / "Table View" toggle
- Default to Card View
- Card View renders ItemCard for each item

Option B: If page uses cards already
- Replace existing card with ItemCard
- Pass item IDs to fetch demand data

Option C: If page is simple list
- Wrap items in grid of ItemCards
```

**Example Implementation (Option A - Add Card View):**
```jsx
import { useState } from 'react';
import { ItemCard } from '@/components/inventory';

export function ItemsPage() {
  const [viewMode, setViewMode] = useState('cards'); // 'cards' | 'table'
  const { items, loading, error } = useItems();

  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <h1>Items</h1>
        <ViewToggle value={viewMode} onChange={setViewMode} />
      </div>

      {viewMode === 'cards' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {items.map(item => (
            <ItemCard 
              key={item.id} 
              itemId={item.id}
              onClick={() => navigate(`/admin/items/${item.id}`)}
            />
          ))}
        </div>
      ) : (
        <ItemsTable items={items} />
      )}
    </div>
  );
}
```

**Verification:**
- [ ] Page renders without errors
- [ ] ItemCards appear in grid

**Commit Message:** `feat(UI-102): integrate ItemCard into items page`

---

### Step 3 of 6: Add data-testid Attributes
**Agent:** Frontend Agent
**Time:** 10 minutes
**Directory:** `frontend/src/pages/admin/`

**Instruction to Agent:**
```
Add data-testid attributes for E2E test selection.
```

**Required Test IDs:**
```jsx
// On the page container
<div data-testid="items-page">

// On view toggle (if added)
<button data-testid="view-toggle-cards">
<button data-testid="view-toggle-table">

// ItemCard already has data-testid="item-card"
```

**Verification:**
- [ ] `data-testid="items-page"` exists
- [ ] `data-testid="item-card"` visible in DOM

**Commit Message:** `chore(UI-102): add test IDs to items page`

---

### Step 4 of 6: Handle Loading States
**Agent:** Frontend Agent
**Time:** 15 minutes

**Instruction to Agent:**
```
Ensure proper loading states when page and ItemCards load.

1. Show skeleton grid while items list loads
2. ItemCard shows its own skeleton while demand data loads
3. Handle error states gracefully
```

**Example:**
```jsx
if (loading) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {[1, 2, 3, 4, 5, 6].map(i => (
        <ItemCardSkeleton key={i} />
      ))}
    </div>
  );
}

if (error) {
  return <ErrorMessage error={error} retry={refetch} />;
}
```

**Verification:**
- [ ] Loading skeleton appears during fetch
- [ ] Error message shows on failure

**Commit Message:** `feat(UI-102): add loading states to items page`

---

### Step 5 of 6: Update E2E Tests to Verify UI
**Agent:** Test Agent
**Time:** 20 minutes
**Directory:** `frontend/tests/e2e/flows/`

**Instruction to Agent:**
```
Update demand-pegging.spec.ts to verify the actual UI now works.

Remove annotation skips and add real UI assertions.
```

**Update:** `frontend/tests/e2e/flows/demand-pegging.spec.ts`
```typescript
test('user can see demand context on items page', async ({ page }) => {
  await seedTestScenario('full-demand-chain');
  await login(page);
  
  // Navigate to items page
  await page.goto('/admin/items');
  
  // Page should load with ItemCards
  await expect(page.getByTestId('items-page')).toBeVisible();
  
  // Find the steel item card (has shortage in scenario)
  const steelCard = page.locator('[data-testid="item-card"]').filter({
    hasText: 'STEEL-SPRING-01'
  });
  
  await expect(steelCard).toBeVisible();
  
  // Should show shortage indicator (red styling)
  await expect(steelCard).toHaveClass(/bg-red|border-red/);
  
  // Should show quantity values
  await expect(steelCard.getByText('45')).toBeVisible();  // on_hand
  await expect(steelCard.getByText('-55')).toBeVisible(); // available
  
  // Should show shortage warning
  await expect(steelCard.getByText(/shortage/i)).toBeVisible();
  
  // Should show linked customer
  await expect(steelCard.getByText(/Acme/i)).toBeVisible();
});

test('user can click through to item detail', async ({ page }) => {
  await seedTestScenario('full-demand-chain');
  await login(page);
  
  await page.goto('/admin/items');
  
  const steelCard = page.locator('[data-testid="item-card"]').filter({
    hasText: 'STEEL-SPRING-01'
  });
  
  await steelCard.getByText('Details →').click();
  
  await expect(page).toHaveURL(/\/admin\/items\/\d+/);
});
```

**Verification:**
- [ ] E2E tests pass with actual UI assertions
- [ ] `npx playwright test demand-pegging --headed` shows cards rendering

**Commit Message:** `test(UI-102): update E2E tests for integrated ItemCard`

---

### Step 6 of 6: Verify Complete Flow
**Agent:** Test Agent
**Time:** 15 minutes

**Instruction to Agent:**
```
Run the full test suite and verify everything works together.
```

**Commands:**
```bash
# Run all E2E tests
npx playwright test

# Run demand pegging tests specifically
npx playwright test demand-pegging

# Run with UI to see it working
npx playwright test demand-pegging --headed

# Take screenshot for documentation
npx playwright test demand-pegging --headed --screenshot=on
```

**Verification:**
- [ ] All E2E tests pass
- [ ] Visual inspection shows ItemCards on items page
- [ ] Color coding works (green for healthy, red for shortage)
- [ ] Clicking through to details works

**Commit Message:** `test(UI-102): verify complete demand pegging flow`

---

## Final Checklist

- [x] Found current items page implementation
- [x] ItemCard integrated into items page
- [x] data-testid attributes added
- [x] Loading states handled
- [x] E2E tests updated and passing
- [x] Visual verification complete
- [x] Documentation updated

---

## Expected Result

Before UI-102:
```
┌─────────────────────────────────────────────────┐
│ Items                                           │
├──────────┬──────────────────┬────────┬─────────┤
│ SKU      │ Name             │ Type   │ Qty     │
├──────────┼──────────────────┼────────┼─────────┤
│ STEEL-01 │ Spring Steel     │ Raw    │ 45      │
│ PLA-BLK  │ Black PLA        │ Raw    │ 100     │
└──────────┴──────────────────┴────────┴─────────┘
```

After UI-102:
```
┌─────────────────────────────────────────────────┐
│ Items                          [Cards] [Table]  │
├─────────────────────────────────────────────────┤
│ ┌─────────────────────┐ ┌─────────────────────┐ │
│ │ 🔴 STEEL-SPRING-01  │ │ 🟢 PLA-BLK-1KG     │ │
│ │ Spring Steel Sheet  │ │ Black PLA Filament │ │
│ │                     │ │                     │ │
│ │ On Hand: 45         │ │ On Hand: 100       │ │
│ │ Allocated: 100      │ │ Allocated: 0       │ │
│ │ Available: -55 ⚠️   │ │ Available: 100     │ │
│ │                     │ │                     │ │
│ │ ⚠️ Shortage: 55     │ │                     │ │
│ │ → WO-2025-0001      │ │                     │ │
│ │ → Acme Corporation  │ │                     │ │
│ └─────────────────────┘ └─────────────────────┘ │
└─────────────────────────────────────────────────┘
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| ItemCard not importing | Check path: `@/components/inventory` or relative |
| Demand data not loading | Verify API endpoint is `/api/v1/items/{id}/demand-summary` |
| No items showing | Check useItems() hook or items API endpoint |
| Styling broken | Verify Tailwind is processing component classes |
| E2E tests timing out | Add `waitForApi` for demand-summary calls |

---

## Handoff

After UI-102 complete:
1. **Epic 1 is fully delivered** - Users can see demand context
2. **Next:** API-201 (SO Blocking Issues) - doc already created
3. Update dev plan to mark UI-102 complete
