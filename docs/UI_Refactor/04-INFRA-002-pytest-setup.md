# INFRA-002: Backend pytest Test Infrastructure
## Ultra-Granular Implementation Guide

---

## Overview

**Goal:** Get pytest running with PostgreSQL test fixtures for API testing
**Total Time:** ~2-3 hours across all steps
**Outcome:** `pytest` executes and passes health check + sample tests

---

## Tech Stack (Confirmed)

| Component | Technology |
|-----------|------------|
| Language | Python 3.11 |
| Framework | FastAPI 0.104.1 |
| Database | PostgreSQL 17.7 |
| DB Driver | psycopg 3.1+ |
| ORM | SQLAlchemy 2.0.23 |
| Validation | Pydantic 2.10.5 |

---

## Agent Types

| Agent | Role | Works In |
|-------|------|----------|
| **Backend Agent** | Python, FastAPI, database | `backend/` directory |
| **Config Agent** | Configuration files, pytest setup | Config files |
| **Test Agent** | Writing test files, fixtures | `tests/` directories |

---

## Step 0: Discovery (Do First)
**Agent:** Backend Agent
**Time:** 5 minutes

**Instruction to Agent:**
```
Before making changes, discover existing test setup:

1. Does backend/tests/ directory exist?
2. Is pytest in requirements.txt?
3. Are there existing test files?
4. What's the database.py structure? (need to understand get_db pattern)
5. What's the auth pattern? (JWT setup)

Report findings before proceeding.
```

If tests exist, this becomes migration/enhancement (like INFRA-001).

---

## Step-by-Step Execution

---

### Step 1 of 9: Verify/Add pytest Dependencies
**Agent:** Backend Agent
**Time:** 3 minutes
**Directory:** `backend/`

**Instruction to Agent:**
```
Check requirements.txt for testing dependencies. Add if missing:

Required packages:
- pytest>=7.0.0
- pytest-asyncio>=0.21.0  (for async FastAPI)
- httpx>=0.24.0  (async test client)
- pytest-cov>=4.0.0  (coverage)

If using pyproject.toml, add to [project.optional-dependencies] or [tool.poetry.group.dev.dependencies]

Install after adding:
pip install -r requirements.txt
```

**Verification:**
- [ ] `pytest --version` works
- [ ] `python -c "import httpx; import pytest_asyncio"` works

**Commit Message:** `chore: add pytest testing dependencies`

---

### Step 2 of 9: Create Test Directory Structure
**Agent:** Config Agent
**Time:** 2 minutes
**Directory:** `backend/`

**Instruction to Agent:**
```
Create test directory structure (if not exists):

backend/
└── tests/
    ├── __init__.py
    ├── conftest.py         # Shared fixtures
    ├── factories.py        # Test data factories
    ├── api/                # API endpoint tests
    │   └── __init__.py
    ├── services/           # Service layer tests
    │   └── __init__.py
    └── integration/        # Integration tests
        └── __init__.py
```

**Commands:**
```bash
mkdir -p tests/api tests/services tests/integration
touch tests/__init__.py tests/conftest.py tests/factories.py
touch tests/api/__init__.py tests/services/__init__.py tests/integration/__init__.py
```

**Verification:**
- [ ] Directory structure exists
- [ ] All `__init__.py` files present

**Commit Message:** `chore: create backend test directory structure`

---

### Step 3 of 9: Create pytest Configuration
**Agent:** Config Agent
**Time:** 5 minutes
**Directory:** `backend/`

**Instruction to Agent:**
```
Create pytest.ini with configuration for async tests and PostgreSQL.
```

**File to Create:** `backend/pytest.ini`
```ini
[pytest]
# Test discovery
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*

# Asyncio configuration (required for FastAPI async tests)
asyncio_mode = auto
asyncio_default_fixture_loop_scope = function

# Markers
markers =
    unit: Unit tests (fast, mocked dependencies)
    integration: Integration tests (uses test database)
    slow: Slow tests (skip with -m "not slow")
    api: API endpoint tests

# Output
addopts = -v --tb=short --strict-markers

# Warnings
filterwarnings =
    ignore::DeprecationWarning
```

**Verification:**
- [ ] `pytest --collect-only` runs without errors

**Commit Message:** `chore: add pytest configuration`

---

### Step 4 of 9: Create Database Test Fixtures
**Agent:** Test Agent
**Time:** 15 minutes
**Directory:** `backend/tests/`

**Instruction to Agent:**
```
Create conftest.py with PostgreSQL test fixtures.

Key decisions:
1. Use separate test database (filaops_test) for isolation
2. Use transactions + rollback for test isolation (fast)
3. Support both sync and async patterns
4. Match existing get_db dependency pattern
```

**File to Create:** `backend/tests/conftest.py`
```python
"""
Shared pytest fixtures for FilaOps backend tests.

Database Strategy:
- Uses separate PostgreSQL database (filaops_test)
- Each test runs in a transaction that rolls back
- Fast isolation without recreating tables
"""
import os
import pytest
from typing import Generator, AsyncGenerator
from sqlalchemy import create_engine, event, text
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from httpx import AsyncClient, ASGITransport

# Adjust these imports to match your project structure
from app.main import app
from app.database import Base, get_db  # or get_async_db if using async
from app.config import settings  # if you have settings


# ============================================================================
# TEST DATABASE CONFIGURATION
# ============================================================================

# Use TEST_DATABASE_URL env var, or construct from main DB URL
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    # Default: same as main but with _test suffix
    # Adjust based on your actual config pattern
    "postgresql+psycopg://postgres:postgres@localhost:5432/filaops_test"
)

# Async version for async tests
TEST_DATABASE_URL_ASYNC = TEST_DATABASE_URL.replace(
    "postgresql+psycopg://", 
    "postgresql+psycopg_async://"
) if "psycopg_async" not in TEST_DATABASE_URL else TEST_DATABASE_URL


# ============================================================================
# SYNC DATABASE FIXTURES
# ============================================================================

@pytest.fixture(scope="session")
def engine():
    """
    Create sync database engine for test session.
    Creates all tables at start, drops at end.
    """
    engine = create_engine(TEST_DATABASE_URL, echo=False)
    
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    yield engine
    
    # Cleanup - drop all tables
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


@pytest.fixture(scope="function")
def db(engine) -> Generator[Session, None, None]:
    """
    Create database session for each test.
    Uses nested transactions for rollback isolation.
    """
    connection = engine.connect()
    transaction = connection.begin()
    
    # Create session bound to this connection
    TestSessionLocal = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=connection
    )
    session = TestSessionLocal()
    
    # Start nested transaction (savepoint)
    nested = connection.begin_nested()
    
    # Restart savepoint after each commit
    @event.listens_for(session, "after_transaction_end")
    def restart_savepoint(sess, trans):
        nonlocal nested
        if trans.nested and not trans._parent.nested:
            nested = connection.begin_nested()
    
    yield session
    
    # Rollback everything
    session.close()
    transaction.rollback()
    connection.close()


# ============================================================================
# ASYNC DATABASE FIXTURES (if using async SQLAlchemy)
# ============================================================================

@pytest.fixture(scope="session")
async def async_engine():
    """Async database engine."""
    engine = create_async_engine(TEST_DATABASE_URL_ASYNC, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    yield engine
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    
    await engine.dispose()


@pytest.fixture(scope="function")
async def async_db(async_engine) -> AsyncGenerator[AsyncSession, None]:
    """Async database session with rollback isolation."""
    async with async_engine.connect() as connection:
        transaction = await connection.begin()
        
        AsyncTestSession = async_sessionmaker(
            bind=connection,
            class_=AsyncSession,
            expire_on_commit=False
        )
        
        async with AsyncTestSession() as session:
            yield session
        
        await transaction.rollback()


# ============================================================================
# API CLIENT FIXTURES
# ============================================================================

@pytest.fixture(scope="function")
def override_get_db(db: Session):
    """Override get_db dependency with test session."""
    def _override():
        try:
            yield db
        finally:
            pass
    return _override


@pytest.fixture(scope="function")
async def client(override_get_db) -> AsyncGenerator[AsyncClient, None]:
    """
    Async HTTP client for API testing.
    
    Usage:
        async def test_endpoint(client):
            response = await client.get("/api/v1/health")
            assert response.status_code == 200
    """
    app.dependency_overrides[get_db] = override_get_db
    
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    
    app.dependency_overrides.clear()


@pytest.fixture(scope="function")
def sync_client(override_get_db):
    """
    Sync HTTP client (uses TestClient).
    Simpler for basic endpoint tests.
    """
    from fastapi.testclient import TestClient
    
    app.dependency_overrides[get_db] = override_get_db
    
    with TestClient(app) as c:
        yield c
    
    app.dependency_overrides.clear()


# ============================================================================
# AUTHENTICATION FIXTURES
# ============================================================================

@pytest.fixture(scope="function")
def test_user(db: Session):
    """Create a test user for auth tests."""
    from tests.factories import create_test_user
    return create_test_user(db)


@pytest.fixture(scope="function")
async def auth_client(client: AsyncClient, test_user) -> AsyncClient:
    """
    Authenticated client with JWT token.
    
    Usage:
        async def test_protected(auth_client):
            response = await auth_client.get("/api/v1/me")
            assert response.status_code == 200
    """
    # Login to get token
    response = await client.post(
        "/api/v1/auth/login",
        data={
            "username": test_user.username,
            "password": "testpass123"
        }
    )
    
    if response.status_code == 200:
        token = response.json().get("access_token")
        client.headers["Authorization"] = f"Bearer {token}"
    
    return client


@pytest.fixture(scope="function")
def auth_sync_client(sync_client, test_user):
    """Sync authenticated client."""
    response = sync_client.post(
        "/api/v1/auth/login",
        data={
            "username": test_user.username,
            "password": "testpass123"
        }
    )
    
    if response.status_code == 200:
        token = response.json().get("access_token")
        sync_client.headers["Authorization"] = f"Bearer {token}"
    
    return sync_client


# ============================================================================
# UTILITY FIXTURES
# ============================================================================

@pytest.fixture(autouse=True)
def reset_sequences():
    """Reset factory sequences between tests."""
    from tests.factories import reset_sequences as _reset
    _reset()
    yield


@pytest.fixture
def query_counter(engine):
    """
    Count SQL queries executed (detect N+1 problems).
    
    Usage:
        def test_no_n_plus_one(db, query_counter):
            # ... do operations ...
            assert query_counter() < 5
    """
    queries = []
    
    @event.listens_for(engine, "before_cursor_execute")
    def capture(conn, cursor, statement, params, context, executemany):
        queries.append(statement)
    
    yield lambda: len(queries)
    
    event.remove(engine, "before_cursor_execute", capture)
```

**Verification:**
- [ ] File created
- [ ] Imports match your project structure (may need adjustment)

**Commit Message:** `feat: add pytest fixtures for PostgreSQL testing`

---

### Step 5 of 9: Create Test Data Factories
**Agent:** Test Agent
**Time:** 20 minutes
**Directory:** `backend/tests/`

**Instruction to Agent:**
```
Create factories.py with test data creation functions.

IMPORTANT: Look at actual models in app/models/ first.
Factories should match your real model fields.
```

**File to Create:** `backend/tests/factories.py`
```python
"""
Test data factories for FilaOps.

Usage:
    from tests.factories import create_test_customer, create_test_sales_order
    
    def test_something(db):
        customer = create_test_customer(db, name="Acme")
        order = create_test_sales_order(db, customer=customer)
"""
from datetime import datetime, date, timedelta
from decimal import Decimal
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session

# ============================================================================
# ADJUST IMPORTS TO MATCH YOUR PROJECT
# ============================================================================
# from app.models import (
#     User, Customer, Vendor, Item, Product, BOMLine,
#     SalesOrder, SalesOrderLine, ProductionOrder,
#     PurchaseOrder, PurchaseOrderLine, Printer,
#     Quote, QuoteLine, Shipment
# )
# from app.auth import get_password_hash


# ============================================================================
# SEQUENCE MANAGEMENT
# ============================================================================

_sequences: Dict[str, int] = {}


def reset_sequences():
    """Reset all sequences. Called between tests."""
    global _sequences
    _sequences = {}


def _next(name: str) -> int:
    """Get next sequence number."""
    _sequences[name] = _sequences.get(name, 0) + 1
    return _sequences[name]


def _code(prefix: str, name: str) -> str:
    """Generate a code like SO-2025-0001."""
    seq = _next(name)
    return f"{prefix}-{datetime.now().year}-{seq:04d}"


# ============================================================================
# USER FACTORY
# ============================================================================

def create_test_user(
    db: Session,
    username: Optional[str] = None,
    password: str = "testpass123",
    **overrides
) -> "User":
    """Create a test user."""
    from app.models import User
    from app.auth import get_password_hash  # Adjust import path
    
    seq = _next("user")
    
    user = User(
        username=username or f"testuser{seq}",
        email=overrides.pop("email", f"test{seq}@example.com"),
        hashed_password=get_password_hash(password),
        is_active=overrides.pop("is_active", True),
        **overrides
    )
    db.add(user)
    db.flush()
    return user


# ============================================================================
# CUSTOMER / VENDOR FACTORIES
# ============================================================================

def create_test_customer(
    db: Session,
    name: Optional[str] = None,
    **overrides
) -> "Customer":
    """Create a test customer."""
    from app.models import Customer
    
    seq = _next("customer")
    
    customer = Customer(
        name=name or f"Test Customer {seq}",
        email=overrides.pop("email", f"customer{seq}@example.com"),
        phone=overrides.pop("phone", f"555-{seq:04d}"),
        **overrides
    )
    db.add(customer)
    db.flush()
    return customer


def create_test_vendor(
    db: Session,
    name: Optional[str] = None,
    **overrides
) -> "Vendor":
    """Create a test vendor."""
    from app.models import Vendor
    
    seq = _next("vendor")
    
    vendor = Vendor(
        name=name or f"Test Vendor {seq}",
        email=overrides.pop("email", f"vendor{seq}@example.com"),
        lead_time_days=overrides.pop("lead_time_days", 3),
        **overrides
    )
    db.add(vendor)
    db.flush()
    return vendor


# ============================================================================
# ITEM / PRODUCT FACTORIES
# ============================================================================

def create_test_item(
    db: Session,
    sku: Optional[str] = None,
    item_type: str = "raw_material",
    **overrides
) -> "Item":
    """
    Create a test inventory item.
    
    item_type: "raw_material", "finished_good", "consumable"
    """
    from app.models import Item
    
    seq = _next("item")
    
    item = Item(
        sku=sku or f"ITEM-{seq:04d}",
        name=overrides.pop("name", f"Test Item {seq}"),
        item_type=item_type,
        unit=overrides.pop("unit", "ea"),
        unit_cost=overrides.pop("unit_cost", Decimal("10.00")),
        reorder_point=overrides.pop("reorder_point", 10),
        **overrides
    )
    db.add(item)
    db.flush()
    return item


def create_test_product(
    db: Session,
    sku: Optional[str] = None,
    bom_items: Optional[List[tuple]] = None,
    **overrides
) -> "Product":
    """
    Create a test product with optional BOM.
    
    Args:
        bom_items: List of (item, qty_per) tuples for BOM
        
    Example:
        item = create_test_item(db)
        product = create_test_product(db, bom_items=[(item, 2.0)])
    """
    from app.models import Product, BOMLine
    
    seq = _next("product")
    
    product = Product(
        sku=sku or f"PROD-{seq:04d}",
        name=overrides.pop("name", f"Test Product {seq}"),
        description=overrides.pop("description", "Test product"),
        unit_price=overrides.pop("unit_price", Decimal("99.99")),
        **overrides
    )
    db.add(product)
    db.flush()
    
    # Create BOM lines if provided
    if bom_items:
        for item, qty_per in bom_items:
            bom_line = BOMLine(
                product_id=product.id,
                item_id=item.id,
                quantity_per=Decimal(str(qty_per))
            )
            db.add(bom_line)
        db.flush()
    
    return product


# ============================================================================
# SALES ORDER FACTORY
# ============================================================================

def create_test_sales_order(
    db: Session,
    customer: Optional["Customer"] = None,
    lines: Optional[List[Dict[str, Any]]] = None,
    **overrides
) -> "SalesOrder":
    """
    Create a test sales order with lines.
    
    Args:
        customer: Customer object (created if not provided)
        lines: List of {"product": Product, "qty": int, "unit_price": Decimal}
        
    Example:
        customer = create_test_customer(db)
        product = create_test_product(db)
        so = create_test_sales_order(db, 
            customer=customer,
            lines=[{"product": product, "qty": 10}]
        )
    """
    from app.models import SalesOrder, SalesOrderLine
    
    if customer is None:
        customer = create_test_customer(db)
    
    code = _code("SO", "sales_order")
    
    so = SalesOrder(
        code=code,
        customer_id=customer.id,
        status=overrides.pop("status", "pending"),
        order_date=overrides.pop("order_date", date.today()),
        ship_date=overrides.pop("ship_date", date.today() + timedelta(days=7)),
        **overrides
    )
    db.add(so)
    db.flush()
    
    # Create lines
    if lines:
        for i, line_data in enumerate(lines, 1):
            product = line_data["product"]
            qty = line_data.get("qty", 1)
            unit_price = line_data.get("unit_price", product.unit_price)
            
            line = SalesOrderLine(
                sales_order_id=so.id,
                line_number=i,
                product_id=product.id,
                quantity=qty,
                unit_price=unit_price,
                total_price=unit_price * qty
            )
            db.add(line)
        db.flush()
    
    return so


# ============================================================================
# PRODUCTION ORDER FACTORY
# ============================================================================

def create_test_production_order(
    db: Session,
    product: Optional["Product"] = None,
    sales_order: Optional["SalesOrder"] = None,
    sales_order_line: Optional[int] = None,
    printer: Optional["Printer"] = None,
    **overrides
) -> "ProductionOrder":
    """
    Create a test production order.
    
    Args:
        product: Product to make (created if not provided)
        sales_order: Linked SO for MTO (None for MTS)
        sales_order_line: Line number on SO
        printer: Assigned printer/machine
    """
    from app.models import ProductionOrder
    
    if product is None:
        product = create_test_product(db)
    
    code = _code("PO", "production_order")
    
    po = ProductionOrder(
        code=code,
        product_id=product.id,
        quantity_ordered=overrides.pop("qty", overrides.pop("quantity_ordered", 10)),
        quantity_completed=overrides.pop("quantity_completed", 0),
        quantity_scrapped=overrides.pop("quantity_scrapped", 0),
        status=overrides.pop("status", "draft"),
        sales_order_id=sales_order.id if sales_order else None,
        sales_order_line=sales_order_line,
        printer_id=printer.id if printer else None,
        **overrides
    )
    db.add(po)
    db.flush()
    return po


# ============================================================================
# PURCHASE ORDER FACTORY
# ============================================================================

def create_test_purchase_order(
    db: Session,
    vendor: Optional["Vendor"] = None,
    lines: Optional[List[Dict[str, Any]]] = None,
    **overrides
) -> "PurchaseOrder":
    """
    Create a test purchase order with lines.
    
    Args:
        vendor: Vendor (created if not provided)
        lines: List of {"item": Item, "qty": int, "unit_cost": Decimal}
    """
    from app.models import PurchaseOrder, PurchaseOrderLine
    
    if vendor is None:
        vendor = create_test_vendor(db)
    
    code = _code("PUR", "purchase_order")
    
    po = PurchaseOrder(
        code=code,
        vendor_id=vendor.id,
        status=overrides.pop("status", "draft"),
        order_date=overrides.pop("order_date", date.today()),
        expected_date=overrides.pop("expected_date", date.today() + timedelta(days=vendor.lead_time_days)),
        **overrides
    )
    db.add(po)
    db.flush()
    
    if lines:
        for i, line_data in enumerate(lines, 1):
            item = line_data["item"]
            qty = line_data.get("qty", 1)
            unit_cost = line_data.get("unit_cost", item.unit_cost)
            
            line = PurchaseOrderLine(
                purchase_order_id=po.id,
                line_number=i,
                item_id=item.id,
                quantity=qty,
                unit_cost=unit_cost
            )
            db.add(line)
        db.flush()
    
    return po


# ============================================================================
# PRINTER FACTORY
# ============================================================================

def create_test_printer(
    db: Session,
    name: Optional[str] = None,
    **overrides
) -> "Printer":
    """Create a test printer/machine."""
    from app.models import Printer
    
    seq = _next("printer")
    
    printer = Printer(
        name=name or f"Printer-{seq:02d}",
        model=overrides.pop("model", "P1S"),
        status=overrides.pop("status", "idle"),
        **overrides
    )
    db.add(printer)
    db.flush()
    return printer


# ============================================================================
# INVENTORY FACTORY
# ============================================================================

def create_test_inventory(
    db: Session,
    item: Optional["Item"] = None,
    qty: int = 100,
    **overrides
) -> "InventoryTransaction":
    """
    Create inventory for an item (receiving transaction).
    """
    from app.models import InventoryTransaction
    
    if item is None:
        item = create_test_item(db)
    
    txn = InventoryTransaction(
        item_id=item.id,
        transaction_type=overrides.pop("transaction_type", "receive"),
        quantity=qty,
        reference=overrides.pop("reference", "TEST-RECEIVE"),
        notes=overrides.pop("notes", "Test inventory setup"),
        **overrides
    )
    db.add(txn)
    db.flush()
    return txn
```

**IMPORTANT:** Agent must verify these factories match actual model fields.

**Verification:**
- [ ] Imports adjusted to match actual model locations
- [ ] Factory fields match actual model fields
- [ ] No import errors when running pytest

**Commit Message:** `feat: add test data factories`

---

### Step 6 of 9: Create Sample Health Test
**Agent:** Test Agent
**Time:** 5 minutes
**Directory:** `backend/tests/`

**Instruction to Agent:**
```
Create a simple health check test to verify setup works.
```

**File to Create:** `backend/tests/test_health.py`
```python
"""
Basic health check tests to verify test setup.
"""
import pytest


class TestHealthCheck:
    """Verify the application starts and responds."""
    
    @pytest.mark.api
    async def test_health_endpoint(self, client):
        """Health endpoint returns 200."""
        response = await client.get("/api/v1/health")
        assert response.status_code == 200
    
    @pytest.mark.api
    async def test_health_response_format(self, client):
        """Health endpoint returns expected format."""
        response = await client.get("/api/v1/health")
        data = response.json()
        
        # Adjust based on your actual health response
        assert "status" in data or response.status_code == 200
    
    @pytest.mark.unit
    def test_database_connection(self, db):
        """Database session works."""
        from sqlalchemy import text
        result = db.execute(text("SELECT 1"))
        assert result.scalar() == 1


class TestAuthSetup:
    """Verify authentication fixtures work."""
    
    @pytest.mark.integration
    def test_user_factory(self, db):
        """Can create test user."""
        from tests.factories import create_test_user
        
        user = create_test_user(db, username="testauth")
        assert user.id is not None
        assert user.username == "testauth"
    
    @pytest.mark.integration
    async def test_authenticated_request(self, auth_client):
        """Authenticated client can access protected routes."""
        # Adjust endpoint to match your actual protected route
        response = await auth_client.get("/api/v1/users/me")
        # Should not be 401
        assert response.status_code != 401
```

**Verification:**
- [ ] Tests run without import errors
- [ ] Adjust endpoint paths to match your actual API

**Commit Message:** `test: add health check tests`

---

### Step 7 of 9: Create Test Database
**Agent:** Backend Agent
**Time:** 5 minutes
**Directory:** `backend/`

**Instruction to Agent:**
```
Create the test database in PostgreSQL.

Option 1 - If using Docker Compose:
The test database might already be configured, check docker-compose.yml

Option 2 - Manual creation:
Connect to PostgreSQL and create the database:

psql -U postgres
CREATE DATABASE filaops_test;
\q

Option 3 - Add to docker-compose.yml:
If not present, add a test database initialization
```

**Verification:**
- [ ] `filaops_test` database exists
- [ ] Connection string in conftest.py is correct

**Commit Message:** `chore: add test database setup`

---

### Step 8 of 9: Add NPM/Make Scripts
**Agent:** Config Agent
**Time:** 5 minutes
**Directory:** `backend/`

**Instruction to Agent:**
```
Add convenience scripts for running tests.

If you have a Makefile, add:
- make test
- make test-cov
- make test-unit
- make test-integration

Or add scripts to pyproject.toml, or create a scripts/ directory.
```

**Add to Makefile (if exists) or create:**
```makefile
# Testing
test:
	pytest

test-cov:
	pytest --cov=app --cov-report=html --cov-report=term

test-unit:
	pytest -m unit

test-integration:
	pytest -m integration

test-api:
	pytest -m api

test-fast:
	pytest -m "not slow"
```

**Verification:**
- [ ] `make test` or `pytest` runs successfully

**Commit Message:** `chore: add test runner scripts`

---

### Step 9 of 9: Run Tests and Verify
**Agent:** Backend Agent
**Time:** 10 minutes
**Directory:** `backend/`

**Instruction to Agent:**
```
Run the tests and fix any issues.

1. First, ensure test database exists and is accessible
2. Run pytest:
   pytest -v

3. If tests fail, check:
   - Import paths in conftest.py and factories.py
   - Database connection string
   - Model field names match factories

4. Fix any issues and re-run until green

Expected: health tests pass, setup is verified
```

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| "ModuleNotFoundError: app" | Run pytest from backend/, check PYTHONPATH |
| "Connection refused" | Start PostgreSQL, check connection string |
| "Relation does not exist" | Tables not created, check Base.metadata |
| "No module named 'tests.factories'" | Missing __init__.py files |

**Verification:**
- [ ] `pytest` runs
- [ ] Health tests pass
- [ ] No import errors

**Commit Message:** `test: verify pytest setup working`

---

## Final Checklist

- [ ] pytest and dependencies installed
- [ ] tests/ directory structure created
- [ ] pytest.ini configured
- [ ] conftest.py with db and client fixtures
- [ ] factories.py with data factories
- [ ] test_health.py passes
- [ ] Test database created
- [ ] Scripts added for running tests

---

## Handoff to Next Ticket

**INFRA-003: Test Data Factories Enhancement**
- Expand factories based on actual models
- Add scenario seeding (for E2E tests)
- Connect frontend E2E `seedTestScenario()` to backend endpoint

---

## Notes for Agents

1. **Check actual models first** - Factories must match real field names
2. **Adjust imports** - Path like `app.models` may differ in your project
3. **Test incrementally** - Run pytest after each change
4. **Don't guess** - If model structure unclear, read the actual model files
5. **PostgreSQL must be running** - Use Docker if needed
