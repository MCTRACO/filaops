# E2E-201: Blocking Issues Flow Tests

## Status: COMPLETE

---

## Overview

**Goal:** End-to-end tests for the blocking issues feature
**Outcome:** Verify blocking issues visibility and suggested actions workflow

---

## What Was Implemented

### Test File

**`frontend/tests/e2e/flows/blocking-issues.spec.ts`**

Tests the complete blocking issues workflow:
1. Sales Order blocking issues panel visibility
2. Production Order blocking issues panel visibility  
3. Suggested actions display and navigation
4. Pre-filled PO modal from shortage action
5. API endpoint verification

---

## Test Cases

| Test | Description | Type |
|------|-------------|------|
| `sales order detail page shows blocking issues panel` | Verifies BlockingIssuesPanel renders on SO detail | UI |
| `blocking issues panel shows suggested actions` | Verifies resolution actions appear | UI |
| `clicking Create PO action navigates to purchasing with pre-filled modal` | Tests full action workflow | UI |
| `production order detail page shows blocking issues panel` | Verifies panel on PO detail | UI |
| `production order shows material issues when short` | Verifies material shortage display | UI |
| `production order shows linked sales order` | Verifies MTO linkage display | UI |
| `SO blocking-issues API returns data` | Validates API-201 endpoint | API |
| `PO blocking-issues API returns data` | Validates API-202 endpoint | API |
| `SO blocking-issues shows resolution actions for shortages` | Validates action generation | API |

---

## Test Data

Uses `so-with-blocking-issues` scenario which creates:
- Sales order with unfulfilled demand
- Production order linked to SO
- Material shortage (insufficient inventory)
- Resolution actions generated

---

## Running the Tests

```bash
# Run blocking issues tests only
npx playwright test blocking-issues

# Run with UI visible
npx playwright test blocking-issues --headed

# Run with debug mode
npx playwright test blocking-issues --debug
```

---

## Dependencies

- `API-201`: SO blocking issues endpoint ✅
- `API-202`: PO blocking issues endpoint ✅
- `UI-201`: BlockingIssuesPanel component ✅
- `UI-202`: Wired into SO detail page ✅
- `UI-203`: Wired into PO detail page ✅
- `UI-204`: Suggested actions navigation ✅

---

## Expected Results

All tests should pass when:
1. Backend is running with seeded test data
2. Frontend is running
3. BlockingIssuesPanel is integrated into order detail pages
4. Suggested actions navigation is working

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No orders found | Check test seeding - `so-with-blocking-issues` scenario |
| Panel not visible | Verify BlockingIssuesPanel import in OrderDetail.jsx |
| Actions not clickable | Check onActionClick handler in panel |
| Modal not opening | Verify AdminPurchasing URL param handling |

---

## Handoff

After E2E-201:
1. Run full CI suite
2. Merge to main if all pass
3. Tag `v2.1.0-demand-pegging`
4. Start Week 4: Sales Order Fulfillment
