# API-201: Sales Order Blocking Issues Endpoint

## Status: COMPLETED

---

## Overview

**Goal:** Create API endpoint that identifies what's blocking a sales order from fulfillment
**Outcome:** `GET /api/v1/sales-orders/{id}/blocking-issues` returns actionable blockers

---

## What Was Implemented

### Files Created

1. **`backend/app/schemas/blocking_issues.py`** - Pydantic schemas
   - `SalesOrderBlockingIssues` - Main response model
   - `StatusSummary` - can_fulfill, blocking_count, estimated_ready_date
   - `LineIssues` - Per-line blocking issues breakdown
   - `BlockingIssue` - Individual blocking issue details
   - `ResolutionAction` - Prioritized resolution actions
   - `IssueType` enum - production_incomplete, production_missing, material_shortage, purchase_pending
   - `IssueSeverity` enum - blocking, warning, info

2. **`backend/app/services/blocking_issues.py`** - Service layer
   - `get_sales_order_blocking_issues()` - Main analysis function
   - `analyze_line_issues()` - Per-line issue detection
   - `get_material_requirements()` - BOM explosion for material needs
   - `get_finished_goods_available()` - Check FG inventory
   - `get_pending_purchase_orders()` - Find POs for materials
   - `generate_resolution_actions()` - Create prioritized action list
   - `estimate_ready_date()` - Calculate when order could be ready

3. **`backend/app/api/v1/endpoints/sales_orders.py`** - API endpoint added
   - `GET /{order_id}/blocking-issues` - Returns blocking analysis

4. **`backend/tests/api/test_blocking_issues.py`** - pytest tests (7 tests)
   - Test 404 for non-existent orders
   - Test can_fulfill=true when no issues
   - Test production_incomplete blocking
   - Test material_shortage blocking
   - Test purchase_pending warnings
   - Test resolution actions generation
   - Test with seeded scenarios

---

## Why This Matters

Currently: Users see a sales order status like "Open" but don't know WHY it can't ship
After API-201: Users see exactly what's blocking fulfillment:
- Which production orders aren't complete
- Which materials are short
- Which purchase orders are needed
- Estimated resolution date

This transforms "why can't we ship?" from a 30-minute investigation into instant visibility.

---

## Response Shape

```json
{
  "sales_order_id": 15,
  "sales_order_code": "SO-2025-0015",
  "customer": "Acme Corporation",
  "order_date": "2025-01-02",
  "requested_date": "2025-01-15",
  
  "status_summary": {
    "can_fulfill": false,
    "blocking_count": 3,
    "estimated_ready_date": "2025-01-18",
    "days_until_ready": 3
  },
  
  "line_issues": [
    {
      "line_number": 1,
      "product_sku": "GADGET-WIDGET-01",
      "product_name": "Gadget Widget Assembly",
      "quantity_ordered": 50,
      "quantity_available": 0,
      "quantity_short": 50,
      
      "blocking_issues": [
        {
          "type": "production_incomplete",
          "severity": "blocking",
          "message": "Production order WO-2025-0042 not complete",
          "reference_type": "production_order",
          "reference_id": 42,
          "reference_code": "WO-2025-0042",
          "details": {
            "status": "in_progress",
            "quantity_ordered": 50,
            "quantity_completed": 20,
            "quantity_remaining": 30,
            "estimated_completion": "2025-01-12"
          }
        },
        {
          "type": "material_shortage",
          "severity": "blocking",
          "message": "Material STEEL-SPRING-01 is 55 units short",
          "reference_type": "item",
          "reference_id": 7,
          "reference_code": "STEEL-SPRING-01",
          "details": {
            "required": 100,
            "available": 45,
            "shortage": 55,
            "incoming_po": "PUR-2025-0012",
            "incoming_date": "2025-01-10"
          }
        }
      ]
    }
  ],
  
  "resolution_actions": [
    {
      "priority": 1,
      "action": "Expedite PO PUR-2025-0012",
      "impact": "Resolves material shortage for WO-2025-0042",
      "reference_type": "purchase_order",
      "reference_id": 12
    },
    {
      "priority": 2,
      "action": "Complete production WO-2025-0042",
      "impact": "Enables fulfillment of line 1",
      "reference_type": "production_order",
      "reference_id": 42
    }
  ]
}
```

---

## Issue Types

| Type | Severity | Description |
|------|----------|-------------|
| `production_incomplete` | blocking | WO exists but not finished |
| `production_missing` | blocking | No WO created for this line |
| `material_shortage` | blocking | Material needed for WO is short |
| `purchase_pending` | warning | PO exists but not received |
| `inventory_reserved` | warning | Stock reserved by other orders |
| `quality_hold` | blocking | Item on quality hold |

---

## Agent Types

| Agent | Role | Works In |
|-------|------|----------|
| **Backend Agent** | FastAPI endpoint, service layer | `backend/app/` |
| **Test Agent** | pytest tests | `backend/tests/` |

---

## Step-by-Step Execution

---

### Step 1 of 8: Write Failing Tests First
**Agent:** Test Agent
**Time:** 20 minutes
**Directory:** `backend/tests/api/`

**File to Create:** `backend/tests/api/test_sales_order_blocking.py`
```python
"""
Tests for GET /api/v1/sales-orders/{id}/blocking-issues endpoint.

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
    create_test_production_order,
    create_test_purchase_order,
    create_test_inventory,
)


class TestSalesOrderBlockingIssues:
    """Tests for sales order blocking issues endpoint."""

    @pytest.mark.api
    async def test_sales_order_not_found(self, client):
        """Non-existent sales order returns 404."""
        response = await client.get("/api/v1/sales-orders/99999/blocking-issues")
        assert response.status_code == 404

    @pytest.mark.api
    async def test_sales_order_no_issues(self, client, db):
        """Sales order with sufficient inventory has no blocking issues."""
        # Setup: Product with enough finished goods inventory
        product = create_test_product(db, sku="READY-PROD")
        create_test_inventory(db, product=product, qty=100)  # FG inventory
        
        customer = create_test_customer(db)
        so = create_test_sales_order(db, customer=customer, lines=[
            {"product": product, "qty": 10}
        ])
        db.commit()

        # Execute
        response = await client.get(f"/api/v1/sales-orders/{so.id}/blocking-issues")
        
        # Verify
        assert response.status_code == 200
        data = response.json()
        
        assert data["sales_order_id"] == so.id
        assert data["status_summary"]["can_fulfill"] is True
        assert data["status_summary"]["blocking_count"] == 0
        assert data["line_issues"][0]["blocking_issues"] == []

    @pytest.mark.api
    async def test_production_incomplete_blocking(self, client, db):
        """Incomplete production order blocks fulfillment."""
        # Setup
        item = create_test_item(db, sku="RAW-MAT")
        create_test_inventory(db, item=item, qty=1000)  # Plenty of material
        
        product = create_test_product(db, sku="MAKE-PROD", bom_items=[(item, Decimal("1"))])
        customer = create_test_customer(db)
        
        so = create_test_sales_order(db, customer=customer, lines=[
            {"product": product, "qty": 50}
        ])
        
        # Production order exists but incomplete
        wo = create_test_production_order(
            db, 
            product=product, 
            qty=50,
            sales_order=so,
            status="in_progress",
            qty_completed=20  # Only 20 of 50 done
        )
        db.commit()

        # Execute
        response = await client.get(f"/api/v1/sales-orders/{so.id}/blocking-issues")
        
        # Verify
        assert response.status_code == 200
        data = response.json()
        
        assert data["status_summary"]["can_fulfill"] is False
        assert data["status_summary"]["blocking_count"] >= 1
        
        # Find the production incomplete issue
        line = data["line_issues"][0]
        assert line["quantity_short"] == 50  # Nothing available yet
        
        issues = line["blocking_issues"]
        prod_issue = next((i for i in issues if i["type"] == "production_incomplete"), None)
        assert prod_issue is not None
        assert prod_issue["severity"] == "blocking"
        assert prod_issue["reference_code"] == wo.code
        assert prod_issue["details"]["quantity_completed"] == 20
        assert prod_issue["details"]["quantity_remaining"] == 30

    @pytest.mark.api
    async def test_material_shortage_blocking(self, client, db):
        """Material shortage for production blocks fulfillment."""
        # Setup: Product needs material we don't have enough of
        item = create_test_item(db, sku="SHORT-MAT")
        create_test_inventory(db, item=item, qty=30)  # Only 30 available
        
        product = create_test_product(db, sku="NEEDS-MAT", bom_items=[(item, Decimal("2"))])
        customer = create_test_customer(db)
        
        so = create_test_sales_order(db, customer=customer, lines=[
            {"product": product, "qty": 50}  # Needs 100 material (50 * 2)
        ])
        
        wo = create_test_production_order(
            db, product=product, qty=50, sales_order=so, status="released"
        )
        db.commit()

        # Execute
        response = await client.get(f"/api/v1/sales-orders/{so.id}/blocking-issues")
        
        # Verify
        assert response.status_code == 200
        data = response.json()
        
        assert data["status_summary"]["can_fulfill"] is False
        
        issues = data["line_issues"][0]["blocking_issues"]
        mat_issue = next((i for i in issues if i["type"] == "material_shortage"), None)
        assert mat_issue is not None
        assert mat_issue["reference_code"] == "SHORT-MAT"
        assert mat_issue["details"]["required"] == 100
        assert mat_issue["details"]["available"] == 30
        assert mat_issue["details"]["shortage"] == 70

    @pytest.mark.api
    async def test_production_missing_blocking(self, client, db):
        """No production order for make-to-order product blocks fulfillment."""
        # Setup: Product with no FG inventory and no production order
        item = create_test_item(db, sku="RAW")
        product = create_test_product(db, sku="MTO-PROD", bom_items=[(item, Decimal("1"))])
        
        customer = create_test_customer(db)
        so = create_test_sales_order(db, customer=customer, lines=[
            {"product": product, "qty": 25}
        ])
        # No production order created!
        db.commit()

        # Execute
        response = await client.get(f"/api/v1/sales-orders/{so.id}/blocking-issues")
        
        # Verify
        assert response.status_code == 200
        data = response.json()
        
        assert data["status_summary"]["can_fulfill"] is False
        
        issues = data["line_issues"][0]["blocking_issues"]
        missing_issue = next((i for i in issues if i["type"] == "production_missing"), None)
        assert missing_issue is not None
        assert missing_issue["severity"] == "blocking"
        assert "no production order" in missing_issue["message"].lower()

    @pytest.mark.api
    async def test_purchase_pending_warning(self, client, db):
        """Pending purchase order shows as warning."""
        # Setup
        item = create_test_item(db, sku="PEND-MAT")
        create_test_inventory(db, item=item, qty=20)
        
        product = create_test_product(db, sku="PEND-PROD", bom_items=[(item, Decimal("1"))])
        customer = create_test_customer(db)
        
        so = create_test_sales_order(db, customer=customer, lines=[
            {"product": product, "qty": 50}
        ])
        
        wo = create_test_production_order(
            db, product=product, qty=50, sales_order=so, status="released"
        )
        
        # Purchase order exists but not received
        vendor = create_test_vendor(db)
        po = create_test_purchase_order(
            db, vendor=vendor, status="ordered",
            lines=[{"item": item, "qty": 100}],
            expected_date=date.today() + timedelta(days=5)
        )
        db.commit()

        # Execute
        response = await client.get(f"/api/v1/sales-orders/{so.id}/blocking-issues")
        
        # Verify
        data = response.json()
        
        # Should have material shortage (blocking) and purchase pending (warning)
        issues = data["line_issues"][0]["blocking_issues"]
        
        po_issue = next((i for i in issues if i["type"] == "purchase_pending"), None)
        assert po_issue is not None
        assert po_issue["severity"] == "warning"
        assert po_issue["reference_code"] == po.code

    @pytest.mark.api
    async def test_resolution_actions_generated(self, client, db):
        """Resolution actions are generated for blocking issues."""
        # Use full-demand-chain scenario
        from tests.scenarios import seed_scenario
        result = seed_scenario(db, "full-demand-chain")
        
        so_id = result["sales_orders"]["main"]["id"]
        
        response = await client.get(f"/api/v1/sales-orders/{so_id}/blocking-issues")
        
        assert response.status_code == 200
        data = response.json()
        
        # Should have resolution actions
        assert "resolution_actions" in data
        assert len(data["resolution_actions"]) > 0
        
        # Actions should be prioritized
        priorities = [a["priority"] for a in data["resolution_actions"]]
        assert priorities == sorted(priorities)

    @pytest.mark.api
    async def test_multiple_lines_with_different_issues(self, client, db):
        """Sales order with multiple lines, each having different issues."""
        # Setup: Two products with different problems
        item1 = create_test_item(db, sku="MAT-1")
        item2 = create_test_item(db, sku="MAT-2")
        create_test_inventory(db, item=item1, qty=100)
        create_test_inventory(db, item=item2, qty=5)  # Short!
        
        product1 = create_test_product(db, sku="PROD-OK", bom_items=[(item1, Decimal("1"))])
        product2 = create_test_product(db, sku="PROD-SHORT", bom_items=[(item2, Decimal("1"))])
        
        customer = create_test_customer(db)
        so = create_test_sales_order(db, customer=customer, lines=[
            {"product": product1, "qty": 10},  # This line OK
            {"product": product2, "qty": 20},  # This line short
        ])
        
        # Production orders for both
        wo1 = create_test_production_order(db, product=product1, qty=10, sales_order=so, status="complete")
        wo2 = create_test_production_order(db, product=product2, qty=20, sales_order=so, status="released")
        db.commit()

        # Execute
        response = await client.get(f"/api/v1/sales-orders/{so.id}/blocking-issues")
        
        # Verify
        data = response.json()
        
        assert len(data["line_issues"]) == 2
        
        # Line 1 should have no blocking issues
        line1 = next(l for l in data["line_issues"] if l["product_sku"] == "PROD-OK")
        assert len(line1["blocking_issues"]) == 0
        
        # Line 2 should have material shortage
        line2 = next(l for l in data["line_issues"] if l["product_sku"] == "PROD-SHORT")
        assert len(line2["blocking_issues"]) > 0
        assert any(i["type"] == "material_shortage" for i in line2["blocking_issues"])
```

**Verification:**
- [ ] File created
- [ ] Tests run and FAIL (expected - TDD)

**Commit Message:** `test(API-201): add failing tests for SO blocking issues`

---

### Step 2 of 8: Create Pydantic Schemas
**Agent:** Backend Agent
**Time:** 15 minutes
**Directory:** `backend/app/schemas/`

**File to Create:** `backend/app/schemas/blocking_issues.py`
```python
"""
Schemas for blocking issues endpoints.
Used by both sales order and production order blocking analysis.
"""
from datetime import date
from decimal import Decimal
from typing import Optional, List, Any, Dict
from enum import Enum
from pydantic import BaseModel, Field


class IssueSeverity(str, Enum):
    """Severity level of a blocking issue."""
    BLOCKING = "blocking"  # Prevents fulfillment
    WARNING = "warning"    # May cause delays
    INFO = "info"          # Informational only


class IssueType(str, Enum):
    """Types of blocking issues."""
    PRODUCTION_INCOMPLETE = "production_incomplete"
    PRODUCTION_MISSING = "production_missing"
    MATERIAL_SHORTAGE = "material_shortage"
    PURCHASE_PENDING = "purchase_pending"
    INVENTORY_RESERVED = "inventory_reserved"
    QUALITY_HOLD = "quality_hold"


class BlockingIssue(BaseModel):
    """A single blocking issue."""
    type: IssueType
    severity: IssueSeverity
    message: str
    reference_type: str = Field(description="Type: 'production_order', 'item', 'purchase_order'")
    reference_id: int
    reference_code: str
    details: Dict[str, Any] = Field(default_factory=dict)


class ResolutionAction(BaseModel):
    """Suggested action to resolve blocking issues."""
    priority: int
    action: str
    impact: str
    reference_type: str
    reference_id: int


class StatusSummary(BaseModel):
    """Summary of fulfillment status."""
    can_fulfill: bool
    blocking_count: int
    estimated_ready_date: Optional[date] = None
    days_until_ready: Optional[int] = None


class LineIssues(BaseModel):
    """Blocking issues for a single sales order line."""
    line_number: int
    product_sku: str
    product_name: str
    quantity_ordered: Decimal
    quantity_available: Decimal
    quantity_short: Decimal
    blocking_issues: List[BlockingIssue]


class SalesOrderBlockingIssues(BaseModel):
    """Complete blocking issues analysis for a sales order."""
    sales_order_id: int
    sales_order_code: str
    customer: str
    order_date: date
    requested_date: Optional[date] = None
    
    status_summary: StatusSummary
    line_issues: List[LineIssues]
    resolution_actions: List[ResolutionAction]

    class Config:
        from_attributes = True
```

**Verification:**
- [ ] File created
- [ ] No Pydantic errors

**Commit Message:** `feat(API-201): add blocking issues Pydantic schemas`

---

### Step 3 of 8: Create Service Layer
**Agent:** Backend Agent
**Time:** 45 minutes
**Directory:** `backend/app/services/`

**File to Create:** `backend/app/services/blocking_issues.py`
```python
"""
Service layer for analyzing blocking issues.
"""
from datetime import date, timedelta
from decimal import Decimal
from typing import Optional, List, Tuple
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from app.models import (
    SalesOrder, SalesOrderLine, ProductionOrder, Product, Item,
    BOMLine, PurchaseOrder, PurchaseOrderLine, Customer,
    InventoryTransaction
)
from app.schemas.blocking_issues import (
    SalesOrderBlockingIssues, StatusSummary, LineIssues,
    BlockingIssue, ResolutionAction, IssueSeverity, IssueType
)


def get_finished_goods_available(db: Session, product_id: int) -> Decimal:
    """Get available finished goods inventory for a product."""
    result = db.execute(
        select(func.coalesce(func.sum(InventoryTransaction.quantity), 0))
        .where(InventoryTransaction.product_id == product_id)
    ).scalar()
    return Decimal(str(result))


def get_production_orders_for_so_line(
    db: Session, 
    sales_order_id: int, 
    product_id: int
) -> List[ProductionOrder]:
    """Get production orders linked to a sales order line."""
    return db.execute(
        select(ProductionOrder)
        .where(ProductionOrder.sales_order_id == sales_order_id)
        .where(ProductionOrder.product_id == product_id)
    ).scalars().all()


def get_material_requirements(db: Session, product_id: int, qty: Decimal) -> List[Tuple[Item, Decimal]]:
    """Get materials required for producing a quantity of product."""
    bom_lines = db.execute(
        select(BOMLine, Item)
        .join(Item, BOMLine.item_id == Item.id)
        .where(BOMLine.product_id == product_id)
    ).all()
    
    return [(item, bom.quantity_per * qty) for bom, item in bom_lines]


def get_item_available(db: Session, item_id: int) -> Decimal:
    """Get available inventory for an item (on_hand - allocated)."""
    # This should use the logic from item_demand service
    from app.services.item_demand import get_item_on_hand, get_work_order_allocations
    
    on_hand = get_item_on_hand(db, item_id)
    allocations = get_work_order_allocations(db, item_id)
    allocated = sum(a.quantity for a in allocations)
    
    return on_hand - allocated


def get_pending_purchase_orders(db: Session, item_id: int) -> List[PurchaseOrder]:
    """Get pending purchase orders for an item."""
    return db.execute(
        select(PurchaseOrder)
        .join(PurchaseOrderLine, PurchaseOrder.id == PurchaseOrderLine.purchase_order_id)
        .where(PurchaseOrderLine.item_id == item_id)
        .where(PurchaseOrder.status.in_(['draft', 'ordered']))
    ).scalars().all()


def analyze_line_issues(
    db: Session,
    so: SalesOrder,
    line: SalesOrderLine
) -> LineIssues:
    """Analyze blocking issues for a single sales order line."""
    product = db.get(Product, line.product_id)
    issues: List[BlockingIssue] = []
    
    # Check finished goods availability
    fg_available = get_finished_goods_available(db, line.product_id)
    qty_short = max(Decimal("0"), line.quantity - fg_available)
    
    if qty_short > 0:
        # Need production - check production orders
        production_orders = get_production_orders_for_so_line(db, so.id, line.product_id)
        
        if not production_orders:
            # No production order exists
            issues.append(BlockingIssue(
                type=IssueType.PRODUCTION_MISSING,
                severity=IssueSeverity.BLOCKING,
                message=f"No production order exists for {product.sku}",
                reference_type="product",
                reference_id=product.id,
                reference_code=product.sku,
                details={
                    "quantity_needed": float(qty_short)
                }
            ))
        else:
            for wo in production_orders:
                remaining = wo.quantity_ordered - wo.quantity_completed - wo.quantity_scrapped
                
                if wo.status not in ['complete', 'closed'] and remaining > 0:
                    # Production incomplete
                    issues.append(BlockingIssue(
                        type=IssueType.PRODUCTION_INCOMPLETE,
                        severity=IssueSeverity.BLOCKING,
                        message=f"Production order {wo.code} not complete",
                        reference_type="production_order",
                        reference_id=wo.id,
                        reference_code=wo.code,
                        details={
                            "status": wo.status,
                            "quantity_ordered": float(wo.quantity_ordered),
                            "quantity_completed": float(wo.quantity_completed),
                            "quantity_remaining": float(remaining),
                            "estimated_completion": wo.needed_date.isoformat() if wo.needed_date else None
                        }
                    ))
                    
                    # Check material availability for this WO
                    material_reqs = get_material_requirements(db, wo.product_id, remaining)
                    for item, qty_needed in material_reqs:
                        available = get_item_available(db, item.id)
                        
                        if available < qty_needed:
                            shortage = qty_needed - available
                            
                            # Check for pending POs
                            pending_pos = get_pending_purchase_orders(db, item.id)
                            incoming_po = pending_pos[0] if pending_pos else None
                            
                            issues.append(BlockingIssue(
                                type=IssueType.MATERIAL_SHORTAGE,
                                severity=IssueSeverity.BLOCKING,
                                message=f"Material {item.sku} is {shortage:.0f} units short",
                                reference_type="item",
                                reference_id=item.id,
                                reference_code=item.sku,
                                details={
                                    "required": float(qty_needed),
                                    "available": float(available),
                                    "shortage": float(shortage),
                                    "incoming_po": incoming_po.code if incoming_po else None,
                                    "incoming_date": incoming_po.expected_date.isoformat() if incoming_po and incoming_po.expected_date else None
                                }
                            ))
                            
                            # Add purchase pending warning if PO exists
                            if incoming_po:
                                issues.append(BlockingIssue(
                                    type=IssueType.PURCHASE_PENDING,
                                    severity=IssueSeverity.WARNING,
                                    message=f"Purchase order {incoming_po.code} pending receipt",
                                    reference_type="purchase_order",
                                    reference_id=incoming_po.id,
                                    reference_code=incoming_po.code,
                                    details={
                                        "status": incoming_po.status,
                                        "expected_date": incoming_po.expected_date.isoformat() if incoming_po.expected_date else None,
                                        "quantity": float(sum(
                                            pol.quantity for pol in incoming_po.lines 
                                            if pol.item_id == item.id
                                        ))
                                    }
                                ))
    
    return LineIssues(
        line_number=line.line_number,
        product_sku=product.sku,
        product_name=product.name,
        quantity_ordered=line.quantity,
        quantity_available=fg_available,
        quantity_short=qty_short,
        blocking_issues=issues
    )


def generate_resolution_actions(line_issues: List[LineIssues]) -> List[ResolutionAction]:
    """Generate prioritized resolution actions from blocking issues."""
    actions: List[ResolutionAction] = []
    priority = 1
    
    # Collect all blocking issues
    all_issues = []
    for line in line_issues:
        all_issues.extend(line.blocking_issues)
    
    # Priority 1: Material shortages with pending POs - expedite
    po_issues = [i for i in all_issues if i.type == IssueType.PURCHASE_PENDING]
    for issue in po_issues:
        actions.append(ResolutionAction(
            priority=priority,
            action=f"Expedite PO {issue.reference_code}",
            impact=f"Resolves material shortage, expected {issue.details.get('expected_date', 'TBD')}",
            reference_type=issue.reference_type,
            reference_id=issue.reference_id
        ))
        priority += 1
    
    # Priority 2: Material shortages without POs - create PO
    mat_issues = [i for i in all_issues if i.type == IssueType.MATERIAL_SHORTAGE]
    for issue in mat_issues:
        if not issue.details.get('incoming_po'):
            actions.append(ResolutionAction(
                priority=priority,
                action=f"Create PO for {issue.reference_code}",
                impact=f"Need {issue.details.get('shortage', 0)} units",
                reference_type=issue.reference_type,
                reference_id=issue.reference_id
            ))
            priority += 1
    
    # Priority 3: Incomplete production - complete WO
    prod_issues = [i for i in all_issues if i.type == IssueType.PRODUCTION_INCOMPLETE]
    for issue in prod_issues:
        actions.append(ResolutionAction(
            priority=priority,
            action=f"Complete production {issue.reference_code}",
            impact=f"{issue.details.get('quantity_remaining', 0)} units remaining",
            reference_type=issue.reference_type,
            reference_id=issue.reference_id
        ))
        priority += 1
    
    # Priority 4: Missing production - create WO
    missing_issues = [i for i in all_issues if i.type == IssueType.PRODUCTION_MISSING]
    for issue in missing_issues:
        actions.append(ResolutionAction(
            priority=priority,
            action=f"Create production order for {issue.reference_code}",
            impact=f"Need {issue.details.get('quantity_needed', 0)} units",
            reference_type=issue.reference_type,
            reference_id=issue.reference_id
        ))
        priority += 1
    
    return actions


def estimate_ready_date(line_issues: List[LineIssues]) -> Optional[date]:
    """Estimate when the order could be ready based on blocking issues."""
    latest_date = date.today()
    
    for line in line_issues:
        for issue in line.blocking_issues:
            if issue.type == IssueType.PURCHASE_PENDING:
                po_date = issue.details.get('expected_date')
                if po_date:
                    po_date = date.fromisoformat(po_date)
                    if po_date > latest_date:
                        latest_date = po_date
            
            elif issue.type == IssueType.PRODUCTION_INCOMPLETE:
                wo_date = issue.details.get('estimated_completion')
                if wo_date:
                    wo_date = date.fromisoformat(wo_date)
                    if wo_date > latest_date:
                        latest_date = wo_date
    
    # Add buffer for production after materials arrive
    if latest_date > date.today():
        latest_date += timedelta(days=2)  # Processing buffer
        return latest_date
    
    return None


def get_sales_order_blocking_issues(
    db: Session, 
    sales_order_id: int
) -> Optional[SalesOrderBlockingIssues]:
    """
    Get complete blocking issues analysis for a sales order.
    
    Returns None if sales order doesn't exist.
    """
    # Get the sales order with related data
    so = db.get(SalesOrder, sales_order_id)
    if not so:
        return None
    
    customer = db.get(Customer, so.customer_id)
    
    # Analyze each line
    line_issues = []
    for line in so.lines:
        line_analysis = analyze_line_issues(db, so, line)
        line_issues.append(line_analysis)
    
    # Calculate summary
    blocking_count = sum(
        len([i for i in line.blocking_issues if i.severity == IssueSeverity.BLOCKING])
        for line in line_issues
    )
    can_fulfill = blocking_count == 0
    
    estimated_ready = estimate_ready_date(line_issues) if not can_fulfill else None
    days_until_ready = (estimated_ready - date.today()).days if estimated_ready else None
    
    # Generate resolution actions
    resolution_actions = generate_resolution_actions(line_issues)
    
    return SalesOrderBlockingIssues(
        sales_order_id=so.id,
        sales_order_code=so.code,
        customer=customer.name if customer else "Unknown",
        order_date=so.order_date,
        requested_date=so.requested_date,
        status_summary=StatusSummary(
            can_fulfill=can_fulfill,
            blocking_count=blocking_count,
            estimated_ready_date=estimated_ready,
            days_until_ready=days_until_ready
        ),
        line_issues=line_issues,
        resolution_actions=resolution_actions
    )
```

**IMPORTANT:** Verify model field names and relationships match your actual models!

**Verification:**
- [ ] File created
- [ ] Imports work

**Commit Message:** `feat(API-201): add blocking issues service layer`

---

### Step 4 of 8: Create API Endpoint
**Agent:** Backend Agent
**Time:** 10 minutes
**Directory:** `backend/app/api/v1/`

**Add to existing sales orders router or create:** `backend/app/api/v1/sales_orders.py`
```python
from app.schemas.blocking_issues import SalesOrderBlockingIssues
from app.services.blocking_issues import get_sales_order_blocking_issues

@router.get("/{sales_order_id}/blocking-issues", response_model=SalesOrderBlockingIssues)
async def get_blocking_issues(
    sales_order_id: int,
    db: Session = Depends(get_db)
):
    """
    Get blocking issues analysis for a sales order.
    
    Returns:
    - Status summary (can_fulfill, blocking_count, estimated_ready_date)
    - Per-line breakdown of blocking issues
    - Prioritized resolution actions
    
    Issue types:
    - production_incomplete: Work order exists but not finished
    - production_missing: No work order created
    - material_shortage: Insufficient material for production
    - purchase_pending: PO exists but not received
    """
    result = get_sales_order_blocking_issues(db, sales_order_id)
    
    if result is None:
        raise HTTPException(status_code=404, detail=f"Sales order {sales_order_id} not found")
    
    return result
```

**Verification:**
- [ ] Endpoint accessible at `/api/v1/sales-orders/{id}/blocking-issues`

**Commit Message:** `feat(API-201): add blocking issues endpoint`

---

### Step 5 of 8: Register Router (if needed)
**Agent:** Backend Agent
**Time:** 5 minutes

**Instruction:** Ensure sales_orders router is registered in main API.

**Commit Message:** `chore(API-201): register sales orders router`

---

### Step 6 of 8: Run Tests and Fix Issues
**Agent:** Backend Agent
**Time:** 30 minutes

```bash
pytest tests/api/test_sales_order_blocking.py -v
```

Fix any issues until all tests pass.

**Commit Message:** `fix(API-201): resolve test failures`

---

### Step 7 of 8: Add Scenario Integration Test
**Agent:** Test Agent
**Time:** 10 minutes

**Add to test file:**
```python
@pytest.mark.integration
async def test_full_demand_chain_blocking_analysis(self, client, db):
    """Verify blocking analysis with full-demand-chain scenario."""
    from tests.scenarios import seed_scenario
    
    result = seed_scenario(db, "full-demand-chain")
    so_id = result["sales_orders"]["main"]["id"]
    
    response = await client.get(f"/api/v1/sales-orders/{so_id}/blocking-issues")
    
    assert response.status_code == 200
    data = response.json()
    
    # The full-demand-chain has a steel shortage
    assert data["status_summary"]["can_fulfill"] is False
    assert data["status_summary"]["blocking_count"] >= 1
    
    # Should have resolution actions
    assert len(data["resolution_actions"]) > 0
    
    # First action should be to expedite the PO
    first_action = data["resolution_actions"][0]
    assert "expedite" in first_action["action"].lower() or "po" in first_action["action"].lower()
```

**Commit Message:** `test(API-201): add scenario integration test`

---

### Step 8 of 8: Update Documentation
**Agent:** Config Agent
**Time:** 5 minutes

Mark API-201 complete in dev plan.

---

## Final Checklist

- [x] Tests written first (TDD)
- [x] Pydantic schemas created
- [x] Service layer with analysis logic
- [x] API endpoint created
- [x] All tests pass
- [x] Documentation updated

---

## API Usage

```typescript
// Get blocking issues for a sales order
const response = await fetch('/api/v1/sales-orders/15/blocking-issues');
const data = await response.json();

if (!data.status_summary.can_fulfill) {
  console.warn(`Order blocked by ${data.status_summary.blocking_count} issues`);
  console.log(`Estimated ready: ${data.status_summary.estimated_ready_date}`);
  
  // Show resolution actions
  data.resolution_actions.forEach(action => {
    console.log(`${action.priority}. ${action.action} - ${action.impact}`);
  });
}
```

---

## Handoff to Next Ticket

**API-202: Production Order Blocking Issues Endpoint**
- Similar analysis but for production orders
- Shows material shortages, equipment issues, labor constraints
- Feeds into the production planning view
