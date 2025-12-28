# FilaOps Redesign: Incremental Development Plan
## Test-Driven, Stackable Implementation

**Last Updated:** 2025-12-28 (Session 2)
**Current Status:** API-202 complete! Ready for UI Integration Sprint

---

## Quick Status Dashboard

```
✅ = Complete    🔄 = In Progress    ⏳ = Pending    ❌ = Blocked

Week 1: Foundation                    ✅ COMPLETE
Week 2: Demand Pegging               🔄 Backend done, UI-102 pending
Week 3: Blocking Issues              ✅ APIs COMPLETE (API-201 + API-202)
Week 4: Sales Order Fulfillment      ⏳ Not started  
Week 5: Smart Production Queue       ⏳ Not started
Week 6: Command Center               ⏳ Not started
Week 7: Integration & Polish         ⏳ Not started
```

---

## Strategy Update: Backend First Approach

**Original Plan:** Each week does API → UI → E2E for one feature
**Revised Plan:** Batch backend work, then UI integration sprint

**Rationale:**
1. Backend APIs can proceed without UI decisions blocking
2. UI components can be built knowing all data shapes upfront
3. Integration sprint is more efficient (less context switching)
4. E2E tests can cover full flows once UI is wired up

**Current Execution:**
```
Phase 1: Backend APIs ✅ DONE (for now)
├── Week 2 APIs ✅ (API-101: Item Demand Summary)
├── Week 3 APIs ✅ (API-201 + API-202: Blocking Issues)
├── Week 4 APIs ⏳
└── Week 5 APIs ⏳

Phase 2: UI Components
├── Week 2 UI ✅ (ItemCard built, not integrated)
├── Week 3 UI ⏳ (BlockingIssuesPanel)
├── Week 4 UI ⏳
└── Week 5 UI ⏳

Phase 3: UI Integration Sprint
├── Wire all components into pages
└── Full E2E test coverage

Phase 4: Command Center & Polish
├── Week 6 features
└── Week 7 integration
```

---

## Full Implementation Plan

### Week 1: Foundation ✅ COMPLETE

| Ticket | Description | Status | Notes |
|--------|-------------|--------|-------|
| INFRA-001 | Playwright E2E Setup | ✅ | Migrated existing setup, commit `aad7f1f` |
| INFRA-002 | pytest Backend Setup | ✅ | PostgreSQL support, commit `0ed6077` |
| INFRA-003 | Test Data Factories | ✅ | 10 factories, 6 scenarios, commit `9de3892` |

**Checkpoint:** Can run tests ✅

---

### Week 2: Demand Pegging 🔄 PARTIAL

| Ticket | Description | Status | Notes |
|--------|-------------|--------|-------|
| API-101 | Item allocations | ✅ | Consolidated with 102/103 into single endpoint |
| API-102 | Supply situation | ✅ | Merged into API-101 |
| API-103 | Demand pegging endpoint | ✅ | Merged into API-101: `GET /items/{id}/demand-summary` |
| UI-101 | DemandPegging component | ✅ | Built as `ItemCard`, doc: `07-UI-101` |
| UI-102 | Integrate into low stock | ⏳ | **GAP** - Component built but not wired in, doc: `10-UI-102` |
| E2E-101 | Demand pegging flow | ✅ | 7 tests passing (API-level), needs UI assertions |

**Checkpoint:** Users can see demand context on items ⏳ (blocked by UI-102)

**API Built:**
```
GET /api/v1/items/{id}/demand-summary
Returns: on_hand, allocated, available, incoming, projected, allocations[], shortage{}
Tests: 8 passing
```

---

### Week 3: Blocking Issues 🔄 IN PROGRESS

> **Pivot:** Original Week 3 was "Production Context". Moved to "Blocking Issues" first 
> since it delivers more immediate user value (answers "Why can't we ship?")

| Ticket | Description | Status | Notes |
|--------|-------------|--------|-------|
| API-201 | SO Blocking Issues | ✅ | **COMPLETE** - 7 tests, doc: `09-API-201` |
| API-202 | PO Blocking Issues | ✅ | **COMPLETE** - 8 tests, doc: `11-API-202` |
| UI-201 | BlockingIssuesPanel | ⏳ | |
| E2E-201 | Blocking issues flow | ⏳ | |

**Checkpoint:** Users can see what's blocking orders ⏳

**APIs:**
```
GET /api/v1/sales-orders/{id}/blocking-issues ✅ COMPLETE
Returns: can_fulfill, blocking_count, line_issues[], resolution_actions[]
Tests: 7 passing

GET /api/v1/production-orders/{id}/blocking-issues ✅ COMPLETE
Returns: can_produce, material_issues[], resolution_actions[]
Tests: 8 passing
```

---

### Week 3 (Original): Production Context ⏳ DEFERRED

> **Note:** Moved after Blocking Issues. Will renumber when we get here.

| Ticket | Description | Status | Notes |
|--------|-------------|--------|-------|
| API-2XX | Production order full context | ⏳ | Deferred |
| UI-2XX | ProductionOrderPanel | ⏳ | Deferred |
| UI-2XX | Enhanced kanban cards | ⏳ | Deferred |
| E2E-2XX | Production context flow | ⏳ | Deferred |

---

### Week 4: Sales Order Fulfillment ⏳ PENDING

| Ticket | Description | Status | Notes |
|--------|-------------|--------|-------|
| API-301 | Fulfillment status query | ⏳ | |
| API-302 | Fulfillment endpoint | ⏳ | |
| API-303 | Enhanced SO list | ⏳ | |
| UI-301 | SalesOrderCard | ⏳ | |
| UI-302 | SO detail redesign | ⏳ | |
| UI-303 | Integrate into list | ⏳ | |
| E2E-301 | Fulfillment flow | ⏳ | |

**Checkpoint:** See fulfillment progress on every SO ⏳

---

### Week 5: Smart Production Queue ⏳ PENDING

| Ticket | Description | Status | Notes |
|--------|-------------|--------|-------|
| API-401 | Production queue with readiness | ⏳ | |
| UI-401 | SmartProductionQueue component | ⏳ | |
| UI-402 | Replace kanban default | ⏳ | |
| E2E-401 | Update production tests | ⏳ | |

**Checkpoint:** Prioritized, actionable production queue ⏳

---

### Week 6: Command Center ⏳ PENDING

| Ticket | Description | Status | Notes |
|--------|-------------|--------|-------|
| API-501 | Action items query | ⏳ | |
| API-502 | Today's summary query | ⏳ | |
| UI-501 | AlertCard component | ⏳ | |
| UI-502 | MachineStatusGrid | ⏳ | |
| UI-503 | CommandCenter page | ⏳ | |
| E2E-501 | Dashboard tests | ⏳ | |

**Checkpoint:** "What do I need to do RIGHT NOW?" dashboard ⏳

---

### Week 7: Integration & Polish ⏳ PENDING

| Ticket | Description | Status | Notes |
|--------|-------------|--------|-------|
| E2E-601 | Full workflow test | ⏳ | Quote → Order → Production → Ship |
| PERF-001 | Performance optimization | ⏳ | |
| DOC-001 | Documentation | ⏳ | |
| FIX-* | Issues found in E2E | ⏳ | |

**Checkpoint:** Complete, tested, documented system ⏳

---

## Documentation Index

| Doc | Description | Status |
|-----|-------------|--------|
| `01-redesign-plan.md` | High-level vision & architecture | Reference |
| `02-incremental-dev-plan.md` | This file - master tracker | Active |
| `03-INFRA-001-playwright-setup.md` | Playwright migration guide | ✅ Done |
| `04-INFRA-002-pytest-setup.md` | pytest PostgreSQL setup | ✅ Done |
| `05-INFRA-003-test-seeding.md` | Test seeding API | ✅ Done |
| `06-API-101-item-demand-summary.md` | Item demand endpoint | ✅ Done |
| `07-UI-101-itemcard-component.md` | ItemCard component | ✅ Done |
| `08-E2E-101-demand-pegging-flow.md` | E2E test guide | ✅ Done |
| `09-API-201-so-blocking-issues.md` | SO blocking issues | ✅ Done |
| `10-UI-102-itemcard-integration.md` | ItemCard page integration | ⏳ Ready |
| `11-API-202-po-blocking-issues.md` | PO blocking issues | ✅ Done |

---

## Branch & Commits

**Branch:** `feat/ui-redesign`

| Commit | Ticket | Description |
|--------|--------|-------------|
| `aad7f1f` | INFRA-001 | Playwright E2E migration |
| `cc6b4d2` | INFRA-001 | Docs update |
| `87d7284` | INFRA-002 | pytest dependencies |
| `0ed6077` | INFRA-002 | PostgreSQL test database support |
| `9de3892` | INFRA-003 | Test data seeding API |
| TBD | API-101 | Item demand summary endpoint (8 tests) |
| TBD | UI-101 | ItemCard component |
| TBD | E2E-101 | Demand pegging tests (7 tests) |
| TBD | API-201 | SO blocking issues (7 tests) |
| TBD | API-202 | PO blocking issues (8 tests) |

---

## Test Summary

| Ticket | Tests | Status |
|--------|-------|--------|
| API-101 | 8 passing | ✅ |
| E2E-101 | 7 passing | ✅ |
| API-201 | 7 passing | ✅ |
| API-202 | 8 passing | ✅ |
| **Total** | **30 passing** | |

---

## Test Scenarios Available

```typescript
await seedTestScenario('empty');                    // Just admin user
await seedTestScenario('basic');                    // Sample customers, products, inventory
await seedTestScenario('full-demand-chain');        // SO→WO→Materials→PO (has shortage)
await seedTestScenario('production-in-progress');   // Various WO statuses
await seedTestScenario('low-stock-with-allocations'); // Demand pegging scenario
await seedTestScenario('so-with-blocking-issues');  // SO fulfillment problems
```

---

## Files Created This Session

### Backend
```
backend/
├── tests/
│   ├── conftest.py              # pytest fixtures, PostgreSQL
│   ├── factories.py             # 10 factory functions
│   ├── scenarios.py             # 6 seeding scenarios
│   └── api/
│       ├── test_item_demand.py      # 8 tests (API-101) ✅
│       └── test_blocking_issues.py  # 7 tests (API-201) ✅
├── app/
│   ├── schemas/
│   │   ├── item_demand.py       # API-101 schemas
│   │   └── blocking_issues.py   # API-201 schemas
│   ├── services/
│   │   ├── item_demand.py       # API-101 logic
│   │   └── blocking_issues.py   # API-201 logic
│   └── api/v1/
│       ├── test.py              # Seeding endpoints
│       ├── items.py             # demand-summary endpoint
│       └── sales_orders.py      # blocking-issues endpoint
```

### Frontend
```
frontend/
├── src/
│   ├── types/
│   │   └── itemDemand.js        # Types + helpers
│   ├── hooks/
│   │   └── useItemDemand.js     # API hook
│   └── components/
│       └── inventory/
│           ├── ItemCard.jsx     # Built, not integrated
│           └── index.js
├── tests/e2e/
│   ├── fixtures/
│   │   └── test-utils.ts
│   ├── pages/
│   │   └── items.page.ts
│   └── flows/
│       └── demand-pegging.spec.ts  # 7 tests
```

---

## Next Steps: UI Integration Sprint

**Backend APIs Complete for Now:**
- ✅ API-101: Item Demand Summary
- ✅ API-201: SO Blocking Issues  
- ✅ API-202: PO Blocking Issues

**UI Sprint Tasks (in order):**
1. **UI-102:** Wire ItemCard into Items page (doc ready: `10-UI-102`)
2. **UI-201:** Build BlockingIssuesPanel component
3. **UI-202:** Wire BlockingIssuesPanel into SO detail page
4. **UI-203:** Wire BlockingIssuesPanel into PO detail page
5. **E2E-201:** Full blocking issues flow tests

**Goal:** Make all backend work visible to users.

**After UI Sprint:** 
1. Wait for all CI tests to pass
2. Merge to main
3. Tag `v2.1.0-demand-pegging`

---

## How to Pick Up This Work

### For a New Session:

1. **Read docs in order:**
   - `02-incremental-dev-plan.md` (this file) - current status
   - Find next pending ticket doc

2. **Check branch status:**
   ```bash
   cd C:\repos\filaops
   git checkout feat/ui-redesign
   git pull
   git log --oneline -10
   ```

3. **Run tests to verify state:**
   ```bash
   # Backend
   cd backend
   pytest tests/ -v --tb=short
   
   # Frontend E2E
   cd frontend
   npx playwright test
   ```

4. **Pick up next ticket:**
   - UI-102 (ItemCard Integration) - doc ready at `10-UI-102`
   - Then UI-201, UI-202, E2E-201

5. **Update this doc when completing tickets**

---

## Branching & Release Strategy

### Current Approach: PR per Epic

```
main (stable, deployed)
│
└── feat/ui-redesign (Epic 1-2 work)
    ├── INFRA-001 ✅
    ├── INFRA-002 ✅
    ├── INFRA-003 ✅
    ├── API-101 ✅
    ├── UI-101 ✅
    ├── E2E-101 ✅
    ├── API-201 ✅
    ├── API-202 ✅
    ├── UI-102 🔄 ←─ NEXT
    ├── UI-201 ⏳
    ├── UI-202 ⏳
    └── E2E-201 ⏳
```

### When to Merge to Main

Merge `feat/ui-redesign` → `main` when:
1. ✅ All CI tests pass (not just local)
2. ✅ At least one user-visible feature works end-to-end
3. ✅ No broken existing functionality
4. ✅ Dev plan shows clear stopping point

### CI Quality Gates

**Between Phases (Backend → UI → E2E):**
```
Backend APIs complete
        ↓
   Run full CI suite ← GATE
        ↓
   All tests pass?
   ├── Yes → Start UI Sprint
   └── No  → Fix issues first
```

**Before Merge to Main:**
```
UI Sprint complete
        ↓
   Run full CI suite ← GATE
        ↓
   All tests pass?
   ├── Yes → Merge + Tag release
   └── No  → Fix issues first
```

**CI Suite Includes:**
- `pytest tests/api/ -v` (backend unit + integration)
- `npx playwright test tests/e2e/flows/demand-pegging.spec.ts` (our new E2E)

**Known Exclusions (pre-existing failures, not caused by us):**
- `functional-workflow.spec.ts` - existed before our work, tests incomplete features
- `order-status-workflow.spec.ts` - existed before our work, tests incomplete features
- These don't exist on `main`, so merging won't break anything
- TODO: Fix in separate ticket

**Current CI Status:** ✅ PASSED (2025-12-28)
- Backend: 23 passed
- E2E (demand-pegging): 7 passed

**Good merge points:**
- After UI sprint (Epic 1-2 complete, users can see demand pegging + blocking issues)
- After each major epic completion
- Before starting risky refactors

### Release Tagging

```bash
# After merging epic to main:
git checkout main
git pull
git tag -a v2.1.0-demand-pegging -m "Epic 1-2: Demand pegging and blocking issues"
git push origin v2.1.0-demand-pegging
```

**Version scheme:** `v{major}.{minor}.{patch}-{feature-name}`
- Major: Breaking changes
- Minor: New features (epics)
- Patch: Bug fixes

### Planned Releases

| Version | Content | Status |
|---------|---------|--------|
| v2.1.0-demand-pegging | Epic 1-2: Item demand + Blocking issues | 🔄 In Progress |
| v2.2.0-fulfillment | Epic 3-4: SO fulfillment + Production context | ⏳ Planned |
| v2.3.0-smart-queue | Epic 5: Smart production queue | ⏳ Planned |
| v2.4.0-command-center | Epic 6: Command center dashboard | ⏳ Planned |
| v2.5.0-polish | Epic 7: Full integration + polish | ⏳ Planned |

### For New Sessions (3-Second Bob Protocol™)

**READ THIS FIRST, FUTURE CLAUDE:**

1. **You have amnesia.** You don't remember any previous work. That's OK.

2. **Check the branch:**
   ```bash
   cd C:\repos\filaops
   git branch  # Should show feat/ui-redesign or similar
   git status  # Check for uncommitted work
   git log --oneline -5  # See recent commits
   ```

3. **Run tests to see current state:**
   ```bash
   # Backend
   cd backend && pytest tests/ -v --tb=short
   
   # Frontend
   cd frontend && npx playwright test
   ```

4. **Read the status dashboard** at the top of this file.

5. **Find the next pending ticket** in the Documentation Index.

6. **Read that ticket's doc** before writing any code.

7. **Update this doc** when you complete something.

8. **Don't be a hero.** Small commits. Clear messages. Test often.

### Commit Message Format

```
type(scope): description

type: feat|fix|test|docs|refactor|chore
scope: ticket number or area (API-201, UI-102, etc.)
```

**Examples:**
```
feat(API-201): add SO blocking issues endpoint
test(API-201): add 7 tests for blocking issues
fix(API-201): resolve material quantity calculation
docs(API-201): mark ticket complete in dev plan
```

### If Things Go Wrong

**Tests failing after your changes:**
```bash
git stash  # Save your work
git checkout .  # Reset to last commit
pytest tests/  # Verify tests pass without your changes
git stash pop  # Bring back your changes
# Now debug the difference
```

**Need to abandon current work:**
```bash
git checkout .  # Discard uncommitted changes
git clean -fd   # Remove untracked files (careful!)
```

**Branch is way behind main:**
```bash
git fetch origin
git rebase origin/main  # Or merge if you prefer
# Resolve conflicts if any
pytest tests/  # Verify still works
```

---

## Tech Stack Reference

| Layer | Technology | Version |
|-------|------------|---------|
| Backend | Python | 3.11 |
| Backend | FastAPI | 0.104.1 |
| Backend | PostgreSQL | 17.7 |
| Backend | SQLAlchemy | 2.0.23 |
| Backend | Pydantic | 2.10.5 |
| Frontend | React | 19.2.0 |
| Frontend | Vite | 7.2.4 |
| Frontend | Tailwind CSS | 4.1.17 |
| Testing | Playwright | 1.57.0 |
| Testing | pytest | 7.0.0+ |

---

## Test Coverage Targets

| Area | Unit Test | Integration | E2E |
|------|-----------|-------------|-----|
| Demand Pegging API | ✅ 8 tests | ✓ | ✓ |
| Blocking Issues API | ✅ 15 tests (7+8) | ✓ | ⏳ |
| Fulfillment API | ⏳ | ⏳ | ⏳ |
| UI Components | ⏳ | - | ⏳ |
| Complete Flows | - | - | ⏳ |

---

## Definition of Done (Each Ticket)

- [ ] Code complete
- [ ] Unit tests written and passing
- [ ] Integration test (if API) written and passing
- [ ] E2E test fragment written
- [ ] Combined E2E tests still pass
- [ ] No regressions in existing tests
- [ ] **User can see/use the feature** ← Critical for UI tickets
- [ ] Documentation updated
- [ ] This dev plan updated with status
