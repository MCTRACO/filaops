# API-101: Item Demand Summary Endpoint

## Status: COMPLETED

---

## Overview

**Goal:** Create API endpoint that returns demand/supply context for inventory items
**Outcome:** `GET /api/v1/items/{id}/demand-summary` returns allocations, incoming, and available qty

---

## What Was Implemented

### Files Created

1. **`backend/app/schemas/item_demand.py`** - Pydantic schemas
   - `ItemDemandSummary` - Main response model
   - `QuantitySummary` - on_hand, allocated, available, incoming, projected
   - `AllocationDetail` - Production order allocations
   - `IncomingDetail` - Purchase order incoming supply
   - `ShortageInfo` - Shortage detection
   - `LinkedSalesOrder` - Sales order traceability

2. **`backend/app/services/item_demand.py`** - Service layer
   - `get_item_on_hand()` - Sum inventory across locations
   - `get_production_order_allocations()` - Find active POs consuming item via BOM
   - `get_incoming_supply()` - Find open PO lines for item
   - `calculate_shortage()` - Detect shortage and blocking orders
   - `get_item_demand_summary()` - Main function combining all

3. **`backend/tests/api/test_item_demand.py`** - Test suite (8 tests)
   - Item not found (404)
   - Item with no allocations
   - Item with production order allocation
   - Item with incoming purchase order
   - Item with shortage
   - Excludes completed production orders
   - Excludes received purchase order lines
   - Integration test with full-demand-chain scenario

### Files Modified

1. **`backend/app/api/v1/endpoints/items.py`**
   - Added import for schemas and service
   - Added `GET /{item_id}/demand-summary` endpoint

---

## Implementation Notes

- Uses `Product` model (not `Item`) to match codebase
- Uses `ProductionOrder` (not `WorkOrder`)
- BOMLine uses `component_id` and `quantity` fields
- Decimals serialize to strings in JSON (tests use `parse_decimal()` helper)
- Active production order statuses: draft, released, scheduled, in_progress
- Open purchase order statuses: draft, ordered, shipped

---

## Why This Matters

Currently: Item pages show just `on_hand` quantity
After API-101: UI can show the full picture:
- What's allocated to production orders
- What's incoming from purchase orders
- What's actually available
- Which orders are consuming this item

This is the foundation for the "demand pegging" visibility that makes the redesign useful.

---

## Response Shape

```json
{
  "item_id": 123,
  "sku": "STEEL-SPRING-01",
  "name": "Spring Steel Sheet",
  
  "quantities": {
    "on_hand": 100,
    "allocated": 80,
    "available": 20,
    "incoming": 50,
    "projected": 70
  },
  
  "allocations": [
    {
      "type": "work_order",
      "reference_code": "WO-2025-0042",
      "reference_id": 42,
      "quantity": 50,
      "needed_date": "2025-01-05",
      "status": "released",
      "linked_sales_order": {
        "code": "SO-2025-0015",
        "id": 15,
        "customer": "Acme Corp"
      }
    },
    {
      "type": "work_order",
      "reference_code": "WO-2025-0043",
      "reference_id": 43,
      "quantity": 30,
      "needed_date": "2025-01-08",
      "status": "draft",
      "linked_sales_order": null
    }
  ],
  
  "incoming": [
    {
      "type": "purchase_order",
      "reference_code": "PUR-2025-0012",
      "reference_id": 12,
      "quantity": 50,
      "expected_date": "2025-01-03",
      "status": "ordered",
      "vendor": "Amazon Business"
    }
  ],
  
  "shortage": {
    "is_short": false,
    "quantity": 0,
    "blocking_orders": []
  }
}
```

---

## Agent Types

| Agent | Role | Works In |
|-------|------|----------|
| **Backend Agent** | FastAPI endpoint, SQLAlchemy queries | `backend/app/` |
| **Test Agent** | pytest tests | `backend/tests/` |

---

## Step-by-Step Execution

---

### Step 1 of 8: Write Failing Test First
**Agent:** Test Agent
**Time:** 15 minutes
**Directory:** `backend/tests/api/`

**Instruction to Agent:**
```
Create test file for the demand summary endpoint.
These tests will FAIL initially - that's expected (TDD).

Test scenarios:
1. Item with no allocations (simple case)
2. Item with work order allocations
3. Item with incoming purchase orders
4. Item with shortage
5. Item not found (404)
```

**File to Create:** `backend/tests/api/test_item_demand.py`
```python
"""
Tests for GET /api/v1/items/{id}/demand-summary endpoint.

TDD: Write tests first, then implement to make them pass.
"""
import pytest
from decimal import Decimal
from datetime import date, timedelta

from tests.factories import (
    create_test_item,
    create_test_product,
    create_test_customer,
    create_test_vendor,
    create_test_sales_order,
    create_test_work_order,
    create_test_purchase_order,
    create_test_inventory,
)


class TestItemDemandSummary:
    """Tests for item demand summary endpoint."""

    @pytest.mark.api
    async def test_item_not_found(self, client):
        """Non-existent item returns 404."""
        response = await client.get("/api/v1/items/99999/demand-summary")
        assert response.status_code == 404

    @pytest.mark.api
    async def test_item_no_allocations(self, client, db):
        """Item with inventory but no allocations."""
        # Setup: Create item with inventory
        item = create_test_item(db, sku="SIMPLE-ITEM")
        create_test_inventory(db, item=item, qty=100)
        db.commit()

        # Execute
        response = await client.get(f"/api/v1/items/{item.id}/demand-summary")
        
        # Verify
        assert response.status_code == 200
        data = response.json()
        
        assert data["item_id"] == item.id
        assert data["sku"] == "SIMPLE-ITEM"
        assert data["quantities"]["on_hand"] == 100
        assert data["quantities"]["allocated"] == 0
        assert data["quantities"]["available"] == 100
        assert data["allocations"] == []
        assert data["shortage"]["is_short"] is False

    @pytest.mark.api
    async def test_item_with_work_order_allocation(self, client, db):
        """Item allocated to work order shows in allocations."""
        # Setup
        item = create_test_item(db, sku="ALLOCATED-ITEM")
        create_test_inventory(db, item=item, qty=100)
        
        product = create_test_product(db, bom_items=[(item, Decimal("2"))])  # 2 per unit
        customer = create_test_customer(db)
        
        # Create SO -> WO chain
        so = create_test_sales_order(db, customer=customer, lines=[
            {"product": product, "qty": 25}
        ])
        wo = create_test_work_order(db, product=product, qty=25, 
                                     sales_order=so, sales_order_line=1,
                                     status="released")
        db.commit()

        # Execute
        response = await client.get(f"/api/v1/items/{item.id}/demand-summary")
        
        # Verify
        assert response.status_code == 200
        data = response.json()
        
        # 25 units * 2 per = 50 allocated
        assert data["quantities"]["allocated"] == 50
        assert data["quantities"]["available"] == 50  # 100 - 50
        
        # Check allocation details
        assert len(data["allocations"]) == 1
        alloc = data["allocations"][0]
        assert alloc["type"] == "work_order"
        assert alloc["reference_code"] == wo.code
        assert alloc["quantity"] == 50
        assert alloc["linked_sales_order"]["code"] == so.code
        assert alloc["linked_sales_order"]["customer"] == customer.name

    @pytest.mark.api
    async def test_item_with_incoming_purchase(self, client, db):
        """Item with incoming purchase order."""
        # Setup
        item = create_test_item(db, sku="INCOMING-ITEM")
        create_test_inventory(db, item=item, qty=20)
        
        vendor = create_test_vendor(db)
        po = create_test_purchase_order(db, vendor=vendor, status="ordered",
                                         lines=[{"item": item, "qty": 100}])
        db.commit()

        # Execute
        response = await client.get(f"/api/v1/items/{item.id}/demand-summary")
        
        # Verify
        assert response.status_code == 200
        data = response.json()
        
        assert data["quantities"]["on_hand"] == 20
        assert data["quantities"]["incoming"] == 100
        assert data["quantities"]["projected"] == 120  # 20 + 100
        
        assert len(data["incoming"]) == 1
        inc = data["incoming"][0]
        assert inc["type"] == "purchase_order"
        assert inc["reference_code"] == po.code
        assert inc["quantity"] == 100
        assert inc["vendor"] == vendor.name

    @pytest.mark.api
    async def test_item_with_shortage(self, client, db):
        """Item with more allocated than available."""
        # Setup
        item = create_test_item(db, sku="SHORT-ITEM")
        create_test_inventory(db, item=item, qty=30)
        
        product = create_test_product(db, bom_items=[(item, Decimal("1"))])
        
        # Two work orders consuming more than available
        wo1 = create_test_work_order(db, product=product, qty=25, status="released")
        wo2 = create_test_work_order(db, product=product, qty=20, status="released")
        db.commit()

        # Execute
        response = await client.get(f"/api/v1/items/{item.id}/demand-summary")
        
        # Verify
        assert response.status_code == 200
        data = response.json()
        
        # 25 + 20 = 45 allocated, only 30 on hand
        assert data["quantities"]["on_hand"] == 30
        assert data["quantities"]["allocated"] == 45
        assert data["quantities"]["available"] == -15  # Negative = shortage
        
        assert data["shortage"]["is_short"] is True
        assert data["shortage"]["quantity"] == 15
        # Both WOs are blocked by shortage
        assert len(data["shortage"]["blocking_orders"]) == 2

    @pytest.mark.api
    async def test_complete_demand_chain(self, client, db):
        """Full scenario: allocations + incoming + shortage resolution."""
        # Use the seeding scenario
        from tests.scenarios import seed_scenario
        result = seed_scenario(db, "full-demand-chain")
        
        # Get the steel item (the one with shortage)
        steel_id = result["items"]["steel"]["id"]
        
        response = await client.get(f"/api/v1/items/{steel_id}/demand-summary")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify the chain is visible
        assert data["quantities"]["on_hand"] == 45
        assert data["quantities"]["allocated"] == 100  # 50 units * 2 springs
        assert len(data["allocations"]) >= 1
        assert len(data["incoming"]) >= 1
        
        # The SO should be visible through the allocation
        alloc = data["allocations"][0]
        assert alloc["linked_sales_order"] is not None
```

**Verification:**
- [ ] File created
- [ ] `pytest tests/api/test_item_demand.py -v` runs (tests should FAIL)

**Commit Message:** `test(API-101): add failing tests for item demand summary`

---

### Step 2 of 8: Create Pydantic Schemas
**Agent:** Backend Agent
**Time:** 10 minutes
**Directory:** `backend/app/schemas/`

**Instruction to Agent:**
```
Create Pydantic schemas for the demand summary response.
Put in existing schemas file or create new one.
```

**File to Create/Update:** `backend/app/schemas/item_demand.py`
```python
"""
Schemas for item demand summary endpoint.
"""
from datetime import date
from decimal import Decimal
from typing import Optional, List
from pydantic import BaseModel, Field


class LinkedSalesOrder(BaseModel):
    """Sales order linked to an allocation."""
    id: int
    code: str
    customer: str


class AllocationDetail(BaseModel):
    """Single allocation consuming inventory."""
    type: str = Field(description="'work_order' or future types")
    reference_code: str
    reference_id: int
    quantity: Decimal
    needed_date: Optional[date] = None
    status: str
    linked_sales_order: Optional[LinkedSalesOrder] = None


class IncomingDetail(BaseModel):
    """Single incoming supply."""
    type: str = Field(description="'purchase_order' or future types")
    reference_code: str
    reference_id: int
    quantity: Decimal
    expected_date: Optional[date] = None
    status: str
    vendor: Optional[str] = None


class ShortageInfo(BaseModel):
    """Shortage details if available < 0."""
    is_short: bool
    quantity: Decimal = Field(description="Positive number representing shortage amount")
    blocking_orders: List[str] = Field(description="Order codes blocked by shortage")


class QuantitySummary(BaseModel):
    """Quantity breakdown."""
    on_hand: Decimal
    allocated: Decimal
    available: Decimal = Field(description="on_hand - allocated")
    incoming: Decimal
    projected: Decimal = Field(description="available + incoming")


class ItemDemandSummary(BaseModel):
    """Complete demand summary for an item."""
    item_id: int
    sku: str
    name: str
    
    quantities: QuantitySummary
    allocations: List[AllocationDetail]
    incoming: List[IncomingDetail]
    shortage: ShortageInfo

    class Config:
        from_attributes = True
```

**Verification:**
- [ ] File created
- [ ] No Pydantic validation errors

**Commit Message:** `feat(API-101): add Pydantic schemas for demand summary`

---

### Step 3 of 8: Create Service Layer Function
**Agent:** Backend Agent
**Time:** 30 minutes
**Directory:** `backend/app/services/`

**Instruction to Agent:**
```
Create service function that calculates demand summary.

This is where the business logic lives:
1. Get item's on-hand quantity
2. Find all work orders using this item (via BOM)
3. Calculate allocations from active work orders
4. Find incoming purchase order lines
5. Calculate shortage if any

Use efficient queries - avoid N+1!
```

**File to Create:** `backend/app/services/item_demand.py`
```python
"""
Service layer for item demand calculations.
"""
from decimal import Decimal
from typing import Optional, List
from sqlalchemy import select, func
from sqlalchemy.orm import Session, joinedload

from app.models import (
    Item, BOMLine, WorkOrder, SalesOrder, SalesOrderLine,
    PurchaseOrder, PurchaseOrderLine, Customer, Vendor,
    InventoryTransaction
)
from app.schemas.item_demand import (
    ItemDemandSummary, QuantitySummary, AllocationDetail,
    IncomingDetail, ShortageInfo, LinkedSalesOrder
)


def get_item_on_hand(db: Session, item_id: int) -> Decimal:
    """
    Calculate current on-hand quantity from inventory transactions.
    
    Sum of all inventory transaction quantities for this item.
    """
    result = db.execute(
        select(func.coalesce(func.sum(InventoryTransaction.quantity), 0))
        .where(InventoryTransaction.item_id == item_id)
    ).scalar()
    
    return Decimal(str(result))


def get_work_order_allocations(db: Session, item_id: int) -> List[AllocationDetail]:
    """
    Get all active work orders consuming this item.
    
    Joins through BOM to find products using this item,
    then finds work orders for those products.
    """
    # Find products that use this item in their BOM
    products_using_item = (
        select(BOMLine.product_id, BOMLine.quantity_per)
        .where(BOMLine.item_id == item_id)
        .subquery()
    )
    
    # Get active work orders for those products
    # Active = not complete, not cancelled
    active_statuses = ['draft', 'released', 'in_progress']
    
    query = (
        select(
            WorkOrder,
            products_using_item.c.quantity_per,
            SalesOrder,
            Customer.name.label('customer_name')
        )
        .join(products_using_item, WorkOrder.product_id == products_using_item.c.product_id)
        .outerjoin(SalesOrder, WorkOrder.sales_order_id == SalesOrder.id)
        .outerjoin(Customer, SalesOrder.customer_id == Customer.id)
        .where(WorkOrder.status.in_(active_statuses))
        .order_by(WorkOrder.needed_date.asc().nullslast())
    )
    
    results = db.execute(query).all()
    
    allocations = []
    for wo, qty_per, so, customer_name in results:
        # Calculate quantity needed: (ordered - completed - scrapped) * qty_per_unit
        remaining = wo.quantity_ordered - wo.quantity_completed - wo.quantity_scrapped
        allocated_qty = remaining * qty_per
        
        linked_so = None
        if so:
            linked_so = LinkedSalesOrder(
                id=so.id,
                code=so.code,
                customer=customer_name or "Unknown"
            )
        
        allocations.append(AllocationDetail(
            type="work_order",
            reference_code=wo.code,
            reference_id=wo.id,
            quantity=allocated_qty,
            needed_date=wo.needed_date,
            status=wo.status,
            linked_sales_order=linked_so
        ))
    
    return allocations


def get_incoming_supply(db: Session, item_id: int) -> List[IncomingDetail]:
    """
    Get all open purchase order lines for this item.
    
    Open = ordered or partially received, not complete/cancelled.
    """
    active_statuses = ['draft', 'ordered', 'partial']
    
    query = (
        select(PurchaseOrderLine, PurchaseOrder, Vendor.name.label('vendor_name'))
        .join(PurchaseOrder, PurchaseOrderLine.purchase_order_id == PurchaseOrder.id)
        .join(Vendor, PurchaseOrder.vendor_id == Vendor.id)
        .where(PurchaseOrderLine.item_id == item_id)
        .where(PurchaseOrder.status.in_(active_statuses))
        .order_by(PurchaseOrder.expected_date.asc().nullslast())
    )
    
    results = db.execute(query).all()
    
    incoming = []
    for pol, po, vendor_name in results:
        # Calculate remaining to receive
        received = getattr(pol, 'quantity_received', 0) or 0
        remaining = pol.quantity - received
        
        if remaining > 0:
            incoming.append(IncomingDetail(
                type="purchase_order",
                reference_code=po.code,
                reference_id=po.id,
                quantity=remaining,
                expected_date=po.expected_date,
                status=po.status,
                vendor=vendor_name
            ))
    
    return incoming


def calculate_shortage(
    available: Decimal,
    allocations: List[AllocationDetail]
) -> ShortageInfo:
    """
    Determine if there's a shortage and which orders are affected.
    """
    if available >= 0:
        return ShortageInfo(is_short=False, quantity=Decimal("0"), blocking_orders=[])
    
    # There's a shortage - find which orders are blocked
    # Sort by priority (needed_date, then by status priority)
    sorted_allocs = sorted(
        allocations,
        key=lambda a: (a.needed_date or date.max, a.status != 'released')
    )
    
    # Walk through allocations, accumulating until we hit shortage
    blocking = []
    running_total = Decimal("0")
    shortage_point = available.copy_abs()  # When we exceed on_hand
    
    # Actually, simpler: all orders are "blocked" if there's a global shortage
    # More sophisticated: calculate which specific orders can't be fulfilled
    for alloc in sorted_allocs:
        running_total += alloc.quantity
        if running_total > available + shortage_point:
            blocking.append(alloc.reference_code)
    
    # If no specific blocking identified, all are potentially affected
    if not blocking:
        blocking = [a.reference_code for a in allocations]
    
    return ShortageInfo(
        is_short=True,
        quantity=available.copy_abs(),  # Positive shortage amount
        blocking_orders=blocking
    )


def get_item_demand_summary(db: Session, item_id: int) -> Optional[ItemDemandSummary]:
    """
    Get complete demand summary for an item.
    
    Returns None if item doesn't exist.
    """
    # Get the item
    item = db.get(Item, item_id)
    if not item:
        return None
    
    # Calculate quantities
    on_hand = get_item_on_hand(db, item_id)
    allocations = get_work_order_allocations(db, item_id)
    incoming_list = get_incoming_supply(db, item_id)
    
    allocated = sum(a.quantity for a in allocations)
    incoming = sum(i.quantity for i in incoming_list)
    available = on_hand - allocated
    projected = available + incoming
    
    shortage = calculate_shortage(available, allocations)
    
    return ItemDemandSummary(
        item_id=item.id,
        sku=item.sku,
        name=item.name,
        quantities=QuantitySummary(
            on_hand=on_hand,
            allocated=allocated,
            available=available,
            incoming=incoming,
            projected=projected
        ),
        allocations=allocations,
        incoming=incoming_list,
        shortage=shortage
    )
```

**IMPORTANT:** Agent must verify model field names match actual models!

**Verification:**
- [ ] File created
- [ ] Imports match actual model locations
- [ ] Field names match actual model fields

**Commit Message:** `feat(API-101): add item demand service layer`

---

### Step 4 of 8: Create API Endpoint
**Agent:** Backend Agent
**Time:** 10 minutes
**Directory:** `backend/app/api/v1/`

**Instruction to Agent:**
```
Create the API endpoint that calls the service function.
Add to existing items router or create new file.
```

**Add to existing items router or create:** `backend/app/api/v1/items.py`
```python
"""
Item-related API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.item_demand import ItemDemandSummary
from app.services.item_demand import get_item_demand_summary

router = APIRouter(prefix="/items", tags=["items"])


@router.get("/{item_id}/demand-summary", response_model=ItemDemandSummary)
async def get_demand_summary(
    item_id: int,
    db: Session = Depends(get_db)
):
    """
    Get demand summary for an inventory item.
    
    Returns:
    - Current on-hand quantity
    - Allocated quantity (work orders)
    - Available quantity (on_hand - allocated)
    - Incoming quantity (purchase orders)
    - Projected quantity (available + incoming)
    - List of allocations with linked sales orders
    - List of incoming supply
    - Shortage information if applicable
    """
    summary = get_item_demand_summary(db, item_id)
    
    if summary is None:
        raise HTTPException(status_code=404, detail=f"Item {item_id} not found")
    
    return summary
```

**Verification:**
- [ ] Router registered in main app
- [ ] Endpoint accessible at `/api/v1/items/{id}/demand-summary`

**Commit Message:** `feat(API-101): add item demand summary endpoint`

---

### Step 5 of 8: Register Router
**Agent:** Backend Agent
**Time:** 5 minutes
**Directory:** `backend/app/`

**Instruction to Agent:**
```
Ensure the items router is registered in the main API router.
Check where other routers are registered and add if missing.
```

**Example addition:**
```python
from app.api.v1.items import router as items_router
api_router.include_router(items_router)
```

**Verification:**
- [ ] `GET /api/v1/items/1/demand-summary` returns response (even if 404)

**Commit Message:** `chore(API-101): register items router`

---

### Step 6 of 8: Run Tests and Fix Issues
**Agent:** Backend Agent
**Time:** 30 minutes
**Directory:** `backend/`

**Instruction to Agent:**
```
Run the tests and fix any issues:

pytest tests/api/test_item_demand.py -v

Common issues to fix:
1. Import paths don't match project structure
2. Model field names differ from schema
3. Query syntax issues with SQLAlchemy 2.0
4. Missing model relationships

Fix issues iteratively until tests pass.
```

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| Import error | Check actual file locations in app/ |
| AttributeError on model | Check actual field names in models |
| Query returns wrong type | SQLAlchemy 2.0 uses `select()` differently |
| Test still fails | Add print statements, check DB state |

**Verification:**
- [ ] All tests in `test_item_demand.py` pass

**Commit Message:** `fix(API-101): resolve test failures`

---

### Step 7 of 8: Add Integration Test with Seeding
**Agent:** Test Agent
**Time:** 10 minutes
**Directory:** `backend/tests/`

**Instruction to Agent:**
```
Add a test that uses the full-demand-chain scenario to verify
the endpoint works with realistic interconnected data.
```

**Add to:** `backend/tests/api/test_item_demand.py`
```python
class TestItemDemandWithScenarios:
    """Tests using seeded scenarios."""

    @pytest.mark.integration
    async def test_full_demand_chain_scenario(self, client, db):
        """Verify endpoint with full-demand-chain scenario."""
        from tests.scenarios import seed_scenario
        
        result = seed_scenario(db, "full-demand-chain")
        steel_id = result["items"]["steel"]["id"]
        
        response = await client.get(f"/api/v1/items/{steel_id}/demand-summary")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify quantities match scenario
        assert data["quantities"]["on_hand"] == 45
        assert data["quantities"]["allocated"] == 100  # 50 gadgets * 2 springs
        assert data["quantities"]["available"] == -55  # Shortage!
        assert data["quantities"]["incoming"] == 100  # PO incoming
        assert data["quantities"]["projected"] == 45   # -55 + 100
        
        # Verify shortage is detected
        assert data["shortage"]["is_short"] is True
        assert data["shortage"]["quantity"] == 55
        
        # Verify traceability - can see the linked SO
        assert len(data["allocations"]) == 1
        assert data["allocations"][0]["linked_sales_order"] is not None
        assert data["allocations"][0]["linked_sales_order"]["customer"] == "Acme Corporation"
```

**Verification:**
- [ ] Test passes

**Commit Message:** `test(API-101): add scenario-based integration test`

---

### Step 8 of 8: Update Documentation
**Agent:** Config Agent
**Time:** 5 minutes
**Directory:** `docs/UI_Refactor/`

**Instruction to Agent:**
```
Mark API-101 as complete in the incremental dev plan.
Note any deviations or learnings.
```

---

## Final Checklist

- [ ] Tests written first (TDD)
- [ ] Pydantic schemas created
- [ ] Service layer with business logic
- [ ] API endpoint created and registered
- [ ] All tests pass
- [ ] Documentation updated

---

## API Usage

After API-101, frontend can call:

```typescript
// Get demand summary for an item
const response = await fetch('/api/v1/items/123/demand-summary');
const data = await response.json();

// Display in UI
console.log(`On hand: ${data.quantities.on_hand}`);
console.log(`Available: ${data.quantities.available}`);
console.log(`Allocated to ${data.allocations.length} work orders`);

if (data.shortage.is_short) {
  console.warn(`SHORTAGE: ${data.shortage.quantity} units short`);
}
```

---

## Handoff to Next Ticket

**UI-101: ItemCard Component with Demand Indicators**
- Uses this endpoint to display demand context
- Shows color-coded availability status
- Links to consuming orders

---

## Notes for Agents

1. **Verify model field names** - Your models may use different names
2. **SQLAlchemy 2.0 syntax** - Use `select()` and `Session.execute()`
3. **Test with seeding** - The scenarios provide realistic test data
4. **Efficient queries** - Avoid N+1 by using joins
5. **Handle nulls** - Dates and relationships may be null
