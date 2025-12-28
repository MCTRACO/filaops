# API-202: Production Order Blocking Issues Endpoint

## Status: COMPLETED

---

## Overview

**Goal:** Create API endpoint that identifies what's blocking a production order from completion
**Outcome:** `GET /api/v1/production-orders/{id}/blocking-issues` returns material shortages and other blockers

---

## What Was Implemented

### Files Modified/Created

1. **`backend/app/schemas/blocking_issues.py`** - Extended with PO schemas
   - `ProductionOrderBlockingIssues` - Main response model
   - `POStatusSummary` - can_produce, blocking_count, estimated_ready_date
   - `MaterialIssue` - Per-material availability and shortage info
   - `IncomingSupply` - Pending purchase order details
   - `LinkedSalesOrderInfo` - MTO sales order linkage
   - `OtherIssue` - Future: machine/quality issues

2. **`backend/app/services/blocking_issues.py`** - Extended with PO functions
   - `get_production_order_blocking_issues()` - Main analysis function
   - `generate_po_resolution_actions()` - Create prioritized action list

3. **`backend/app/api/v1/endpoints/production_orders.py`** - API endpoint added
   - `GET /{order_id}/blocking-issues` - Returns blocking analysis

4. **`backend/tests/api/test_po_blocking_issues.py`** - pytest tests (8 tests)
   - Test 404 for non-existent orders
   - Test can_produce=true when no issues
   - Test material_shortage blocking
   - Test incoming PO shown
   - Test linked sales order shown
   - Test resolution actions generation
   - Test multiple material statuses
   - Test with seeded scenarios

---

## Why This Matters

API-201 answers "Why can't we SHIP this sales order?"
API-202 answers "Why can't we PRODUCE this production order?"

Together they give complete visibility into the manufacturing pipeline.

---

## Response Shape

```json
{
  "production_order_id": 42,
  "production_order_code": "WO-2025-0042",
  "product_sku": "GADGET-WIDGET-01",
  "product_name": "Gadget Widget Assembly",
  
  "quantity_ordered": 50,
  "quantity_completed": 20,
  "quantity_remaining": 30,
  
  "status_summary": {
    "can_produce": false,
    "blocking_count": 2,
    "estimated_ready_date": "2025-01-10",
    "days_until_ready": 5
  },
  
  "linked_sales_order": {
    "id": 15,
    "code": "SO-2025-0015",
    "customer": "Acme Corporation",
    "requested_date": "2025-01-15"
  },
  
  "material_issues": [
    {
      "item_id": 7,
      "item_sku": "STEEL-SPRING-01",
      "item_name": "Spring Steel Sheet",
      "quantity_required": 60,
      "quantity_available": 45,
      "quantity_short": 15,
      "status": "shortage",
      "incoming_supply": {
        "purchase_order_id": 12,
        "purchase_order_code": "PUR-2025-0012",
        "quantity": 100,
        "expected_date": "2025-01-08",
        "vendor": "Amazon Business"
      }
    },
    {
      "item_id": 8,
      "item_sku": "PLA-BLK-1KG",
      "item_name": "Black PLA Filament",
      "quantity_required": 2.5,
      "quantity_available": 6.7,
      "quantity_short": 0,
      "status": "ok",
      "incoming_supply": null
    }
  ],
  
  "other_issues": [
    {
      "type": "machine_unavailable",
      "severity": "warning",
      "message": "Assigned printer P1S-01 is offline",
      "details": {}
    }
  ],
  
  "resolution_actions": [
    {
      "priority": 1,
      "action": "Expedite PO PUR-2025-0012",
      "impact": "Resolves steel shortage, expected Jan 8",
      "reference_type": "purchase_order",
      "reference_id": 12
    },
    {
      "priority": 2,
      "action": "Check printer P1S-01 status",
      "impact": "May need to reassign to different machine",
      "reference_type": "printer",
      "reference_id": 1
    }
  ]
}
```

---

## Reuse from API-201

Much of API-201's code can be reused:
- `IssueSeverity` enum ✅
- `IssueType` enum (extend with new types)
- `ResolutionAction` schema ✅
- Material availability logic (already in `blocking_issues.py`)

---

## Step-by-Step Execution

---

### Step 1 of 6: Write Failing Tests First
**Agent:** Test Agent
**Time:** 15 minutes
**Directory:** `backend/tests/api/`

**Add to existing file or create:** `backend/tests/api/test_po_blocking_issues.py`
```python
"""
Tests for GET /api/v1/production-orders/{id}/blocking-issues endpoint.
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
    create_test_production_order,
    create_test_purchase_order,
    create_test_inventory,
)


class TestProductionOrderBlockingIssues:
    """Tests for production order blocking issues endpoint."""

    @pytest.mark.api
    async def test_production_order_not_found(self, client):
        """Non-existent production order returns 404."""
        response = await client.get("/api/v1/production-orders/99999/blocking-issues")
        assert response.status_code == 404

    @pytest.mark.api
    async def test_production_order_no_issues(self, client, db):
        """Production order with sufficient materials has no blocking issues."""
        # Setup: Product with enough raw materials
        item = create_test_item(db, sku="AVAIL-MAT")
        create_test_inventory(db, item=item, qty=1000)
        
        product = create_test_product(db, bom_items=[(item, Decimal("1"))])
        wo = create_test_production_order(db, product=product, qty=50, status="released")
        db.commit()

        response = await client.get(f"/api/v1/production-orders/{wo.id}/blocking-issues")
        
        assert response.status_code == 200
        data = response.json()
        
        assert data["production_order_id"] == wo.id
        assert data["status_summary"]["can_produce"] is True
        assert data["status_summary"]["blocking_count"] == 0
        assert all(m["status"] == "ok" for m in data["material_issues"])

    @pytest.mark.api
    async def test_material_shortage_blocking(self, client, db):
        """Material shortage blocks production."""
        # Setup: Need 100, only have 30
        item = create_test_item(db, sku="SHORT-MAT")
        create_test_inventory(db, item=item, qty=30)
        
        product = create_test_product(db, bom_items=[(item, Decimal("2"))])  # 2 per unit
        wo = create_test_production_order(db, product=product, qty=50, status="released")
        # Needs 100 (50 * 2), only 30 available
        db.commit()

        response = await client.get(f"/api/v1/production-orders/{wo.id}/blocking-issues")
        
        assert response.status_code == 200
        data = response.json()
        
        assert data["status_summary"]["can_produce"] is False
        assert data["status_summary"]["blocking_count"] >= 1
        
        # Find the material issue
        mat_issue = next(m for m in data["material_issues"] if m["item_sku"] == "SHORT-MAT")
        assert mat_issue["quantity_required"] == 100
        assert mat_issue["quantity_available"] == 30
        assert mat_issue["quantity_short"] == 70
        assert mat_issue["status"] == "shortage"

    @pytest.mark.api
    async def test_material_shortage_with_incoming_po(self, client, db):
        """Shows incoming PO that will resolve shortage."""
        item = create_test_item(db, sku="PEND-MAT")
        create_test_inventory(db, item=item, qty=20)
        
        product = create_test_product(db, bom_items=[(item, Decimal("1"))])
        wo = create_test_production_order(db, product=product, qty=50, status="released")
        
        # Incoming PO
        vendor = create_test_vendor(db)
        po = create_test_purchase_order(
            db, vendor=vendor, status="ordered",
            lines=[{"item": item, "qty": 100}],
            expected_date=date.today() + timedelta(days=3)
        )
        db.commit()

        response = await client.get(f"/api/v1/production-orders/{wo.id}/blocking-issues")
        
        data = response.json()
        
        mat_issue = next(m for m in data["material_issues"] if m["item_sku"] == "PEND-MAT")
        assert mat_issue["incoming_supply"] is not None
        assert mat_issue["incoming_supply"]["purchase_order_code"] == po.code
        assert mat_issue["incoming_supply"]["quantity"] == 100

    @pytest.mark.api
    async def test_linked_sales_order_shown(self, client, db):
        """Shows linked sales order for MTO production."""
        item = create_test_item(db)
        create_test_inventory(db, item=item, qty=1000)
        
        product = create_test_product(db, bom_items=[(item, Decimal("1"))])
        customer = create_test_customer(db, name="Test Customer")
        
        so = create_test_sales_order(db, customer=customer, lines=[
            {"product": product, "qty": 25}
        ])
        wo = create_test_production_order(
            db, product=product, qty=25, 
            sales_order=so, status="released"
        )
        db.commit()

        response = await client.get(f"/api/v1/production-orders/{wo.id}/blocking-issues")
        
        data = response.json()
        
        assert data["linked_sales_order"] is not None
        assert data["linked_sales_order"]["code"] == so.code
        assert data["linked_sales_order"]["customer"] == "Test Customer"

    @pytest.mark.api
    async def test_resolution_actions_generated(self, client, db):
        """Resolution actions are generated for blocking issues."""
        item = create_test_item(db, sku="ACTION-MAT")
        create_test_inventory(db, item=item, qty=10)
        
        product = create_test_product(db, bom_items=[(item, Decimal("1"))])
        wo = create_test_production_order(db, product=product, qty=50, status="released")
        
        vendor = create_test_vendor(db)
        po = create_test_purchase_order(
            db, vendor=vendor, status="ordered",
            lines=[{"item": item, "qty": 100}]
        )
        db.commit()

        response = await client.get(f"/api/v1/production-orders/{wo.id}/blocking-issues")
        
        data = response.json()
        
        assert len(data["resolution_actions"]) > 0
        # First action should be to expedite the PO
        assert "expedite" in data["resolution_actions"][0]["action"].lower() or \
               "po" in data["resolution_actions"][0]["action"].lower()

    @pytest.mark.api
    async def test_multiple_material_shortages(self, client, db):
        """Multiple materials with different availability states."""
        item1 = create_test_item(db, sku="MAT-OK")
        item2 = create_test_item(db, sku="MAT-SHORT")
        item3 = create_test_item(db, sku="MAT-ZERO")
        
        create_test_inventory(db, item=item1, qty=200)  # Plenty
        create_test_inventory(db, item=item2, qty=30)   # Short
        # item3 has no inventory
        
        product = create_test_product(db, bom_items=[
            (item1, Decimal("1")),
            (item2, Decimal("1")),
            (item3, Decimal("1")),
        ])
        wo = create_test_production_order(db, product=product, qty=50, status="released")
        db.commit()

        response = await client.get(f"/api/v1/production-orders/{wo.id}/blocking-issues")
        
        data = response.json()
        
        assert len(data["material_issues"]) == 3
        
        mat_ok = next(m for m in data["material_issues"] if m["item_sku"] == "MAT-OK")
        mat_short = next(m for m in data["material_issues"] if m["item_sku"] == "MAT-SHORT")
        mat_zero = next(m for m in data["material_issues"] if m["item_sku"] == "MAT-ZERO")
        
        assert mat_ok["status"] == "ok"
        assert mat_short["status"] == "shortage"
        assert mat_zero["status"] == "shortage"
        assert mat_zero["quantity_available"] == 0


class TestPOBlockingIssuesWithScenarios:
    """Tests using seeded scenarios."""

    @pytest.mark.integration
    async def test_full_demand_chain_scenario(self, client, db):
        """Verify with full-demand-chain scenario."""
        from tests.scenarios import seed_scenario
        
        result = seed_scenario(db, "full-demand-chain")
        wo_id = result["production_orders"]["main"]["id"]
        
        response = await client.get(f"/api/v1/production-orders/{wo_id}/blocking-issues")
        
        assert response.status_code == 200
        data = response.json()
        
        # This scenario has a steel shortage
        assert data["status_summary"]["can_produce"] is False
        
        # Should show linked SO
        assert data["linked_sales_order"] is not None
        assert "Acme" in data["linked_sales_order"]["customer"]
        
        # Should have resolution actions
        assert len(data["resolution_actions"]) > 0
```

**Verification:**
- [ ] Tests run and FAIL (expected - TDD)

**Commit Message:** `test(API-202): add failing tests for PO blocking issues`

---

### Step 2 of 6: Extend Pydantic Schemas
**Agent:** Backend Agent
**Time:** 10 minutes
**Directory:** `backend/app/schemas/`

**Update:** `backend/app/schemas/blocking_issues.py`
```python
# Add these schemas to the existing file:

class IncomingSupply(BaseModel):
    """Incoming supply from purchase order."""
    purchase_order_id: int
    purchase_order_code: str
    quantity: Decimal
    expected_date: Optional[date] = None
    vendor: str


class MaterialIssue(BaseModel):
    """Material availability for production."""
    item_id: int
    item_sku: str
    item_name: str
    quantity_required: Decimal
    quantity_available: Decimal
    quantity_short: Decimal
    status: str  # 'ok', 'shortage', 'warning'
    incoming_supply: Optional[IncomingSupply] = None


class LinkedSalesOrderInfo(BaseModel):
    """Sales order linked to production order."""
    id: int
    code: str
    customer: str
    requested_date: Optional[date] = None


class POStatusSummary(BaseModel):
    """Summary of production readiness."""
    can_produce: bool
    blocking_count: int
    estimated_ready_date: Optional[date] = None
    days_until_ready: Optional[int] = None


class OtherIssue(BaseModel):
    """Non-material blocking issue."""
    type: str  # 'machine_unavailable', 'quality_hold', etc.
    severity: IssueSeverity
    message: str
    details: Dict[str, Any] = Field(default_factory=dict)


class ProductionOrderBlockingIssues(BaseModel):
    """Complete blocking issues analysis for a production order."""
    production_order_id: int
    production_order_code: str
    product_sku: str
    product_name: str
    
    quantity_ordered: Decimal
    quantity_completed: Decimal
    quantity_remaining: Decimal
    
    status_summary: POStatusSummary
    linked_sales_order: Optional[LinkedSalesOrderInfo] = None
    material_issues: List[MaterialIssue]
    other_issues: List[OtherIssue] = Field(default_factory=list)
    resolution_actions: List[ResolutionAction]

    class Config:
        from_attributes = True
```

**Verification:**
- [ ] No Pydantic errors

**Commit Message:** `feat(API-202): add PO blocking issues schemas`

---

### Step 3 of 6: Add Service Function
**Agent:** Backend Agent
**Time:** 25 minutes
**Directory:** `backend/app/services/`

**Update:** `backend/app/services/blocking_issues.py`
```python
# Add this function to the existing file:

def get_production_order_blocking_issues(
    db: Session,
    production_order_id: int
) -> Optional[ProductionOrderBlockingIssues]:
    """
    Get complete blocking issues analysis for a production order.
    
    Returns None if production order doesn't exist.
    """
    # Get the production order
    wo = db.get(ProductionOrder, production_order_id)
    if not wo:
        return None
    
    product = db.get(Product, wo.product_id)
    
    # Get linked sales order if exists
    linked_so = None
    if wo.sales_order_id:
        so = db.get(SalesOrder, wo.sales_order_id)
        if so:
            customer = db.get(Customer, so.customer_id)
            linked_so = LinkedSalesOrderInfo(
                id=so.id,
                code=so.code,
                customer=customer.name if customer else "Unknown",
                requested_date=so.requested_date
            )
    
    # Calculate remaining quantity
    qty_remaining = wo.quantity_ordered - wo.quantity_completed - wo.quantity_scrapped
    
    # Analyze material requirements
    material_issues = []
    blocking_count = 0
    latest_incoming_date = None
    
    # Get BOM for this product
    bom_lines = db.execute(
        select(BOMLine, Item)
        .join(Item, BOMLine.item_id == Item.id)
        .where(BOMLine.product_id == wo.product_id)
    ).all()
    
    for bom_line, item in bom_lines:
        qty_required = bom_line.quantity_per * qty_remaining
        qty_available = get_item_available(db, item.id)
        qty_short = max(Decimal("0"), qty_required - qty_available)
        
        status = "ok" if qty_short == 0 else "shortage"
        if qty_short > 0:
            blocking_count += 1
        
        # Check for incoming supply
        incoming = None
        pending_pos = get_pending_purchase_orders(db, item.id)
        if pending_pos:
            po = pending_pos[0]
            vendor = db.get(Vendor, po.vendor_id)
            po_qty = sum(
                pol.quantity for pol in po.lines 
                if pol.item_id == item.id
            )
            incoming = IncomingSupply(
                purchase_order_id=po.id,
                purchase_order_code=po.code,
                quantity=po_qty,
                expected_date=po.expected_date,
                vendor=vendor.name if vendor else "Unknown"
            )
            
            if po.expected_date and (latest_incoming_date is None or po.expected_date > latest_incoming_date):
                latest_incoming_date = po.expected_date
        
        material_issues.append(MaterialIssue(
            item_id=item.id,
            item_sku=item.sku,
            item_name=item.name,
            quantity_required=qty_required,
            quantity_available=max(Decimal("0"), qty_available),
            quantity_short=qty_short,
            status=status,
            incoming_supply=incoming
        ))
    
    # Determine if can produce
    can_produce = blocking_count == 0
    
    # Estimate ready date
    estimated_ready = None
    days_until_ready = None
    if not can_produce and latest_incoming_date:
        estimated_ready = latest_incoming_date + timedelta(days=1)  # Buffer
        days_until_ready = (estimated_ready - date.today()).days
    
    # Generate resolution actions
    resolution_actions = generate_po_resolution_actions(material_issues)
    
    return ProductionOrderBlockingIssues(
        production_order_id=wo.id,
        production_order_code=wo.code,
        product_sku=product.sku,
        product_name=product.name,
        quantity_ordered=wo.quantity_ordered,
        quantity_completed=wo.quantity_completed,
        quantity_remaining=qty_remaining,
        status_summary=POStatusSummary(
            can_produce=can_produce,
            blocking_count=blocking_count,
            estimated_ready_date=estimated_ready,
            days_until_ready=days_until_ready
        ),
        linked_sales_order=linked_so,
        material_issues=material_issues,
        other_issues=[],  # Future: machine status, quality holds
        resolution_actions=resolution_actions
    )


def generate_po_resolution_actions(material_issues: List[MaterialIssue]) -> List[ResolutionAction]:
    """Generate prioritized resolution actions for production blocking issues."""
    actions = []
    priority = 1
    
    # Priority 1: Expedite existing POs for shortage materials
    for mat in material_issues:
        if mat.status == "shortage" and mat.incoming_supply:
            actions.append(ResolutionAction(
                priority=priority,
                action=f"Expedite PO {mat.incoming_supply.purchase_order_code}",
                impact=f"Resolves {mat.item_sku} shortage, expected {mat.incoming_supply.expected_date or 'TBD'}",
                reference_type="purchase_order",
                reference_id=mat.incoming_supply.purchase_order_id
            ))
            priority += 1
    
    # Priority 2: Create POs for shortage materials without incoming
    for mat in material_issues:
        if mat.status == "shortage" and not mat.incoming_supply:
            actions.append(ResolutionAction(
                priority=priority,
                action=f"Create PO for {mat.item_sku}",
                impact=f"Need {mat.quantity_short} units",
                reference_type="item",
                reference_id=mat.item_id
            ))
            priority += 1
    
    return actions
```

**Verification:**
- [ ] Function added
- [ ] Imports work

**Commit Message:** `feat(API-202): add PO blocking issues service function`

---

### Step 4 of 6: Create API Endpoint
**Agent:** Backend Agent
**Time:** 10 minutes
**Directory:** `backend/app/api/v1/`

**Add to production orders router:**
```python
from app.schemas.blocking_issues import ProductionOrderBlockingIssues
from app.services.blocking_issues import get_production_order_blocking_issues

@router.get("/{production_order_id}/blocking-issues", response_model=ProductionOrderBlockingIssues)
async def get_po_blocking_issues(
    production_order_id: int,
    db: Session = Depends(get_db)
):
    """
    Get blocking issues analysis for a production order.
    
    Returns:
    - Status summary (can_produce, blocking_count, estimated_ready_date)
    - Linked sales order (if MTO)
    - Material requirements with availability status
    - Resolution actions to unblock production
    """
    result = get_production_order_blocking_issues(db, production_order_id)
    
    if result is None:
        raise HTTPException(status_code=404, detail=f"Production order {production_order_id} not found")
    
    return result
```

**Verification:**
- [ ] Endpoint accessible at `/api/v1/production-orders/{id}/blocking-issues`

**Commit Message:** `feat(API-202): add PO blocking issues endpoint`

---

### Step 5 of 6: Run Tests and Fix Issues
**Agent:** Backend Agent
**Time:** 20 minutes

```bash
pytest tests/api/test_po_blocking_issues.py -v
```

Fix any issues until all tests pass.

**Commit Message:** `fix(API-202): resolve test failures`

---

### Step 6 of 6: Update Documentation
**Agent:** Config Agent
**Time:** 5 minutes

Mark API-202 complete in dev plan.

---

## Final Checklist

- [x] Tests written first (TDD)
- [x] Schemas extended
- [x] Service function added
- [x] API endpoint created
- [x] All tests pass
- [x] Documentation updated

---

## API Pair Complete

With API-201 and API-202 done:

```
GET /api/v1/sales-orders/{id}/blocking-issues
→ "Why can't we SHIP this order?"

GET /api/v1/production-orders/{id}/blocking-issues  
→ "Why can't we PRODUCE this order?"
```

---

## Next: UI Integration Sprint

After API-202, recommended to switch to UI:
1. **UI-102:** Wire ItemCard into Items page
2. **UI-201:** Build BlockingIssuesPanel component
3. **UI-202:** Wire into SO detail page
4. **UI-203:** Wire into PO detail page
5. **E2E tests:** Full flow verification

This delivers visible user value from all the backend work.
