# UI-101: ItemCard Component with Demand Indicators

## Status: COMPLETED

---

## Overview

**Goal:** Create React component that displays item demand context
**Outcome:** `<ItemCard itemId={123} />` shows on-hand, allocated, available with visual indicators

---

## What Was Implemented

### Files Created

1. **`frontend/src/types/itemDemand.js`** - Type definitions with JSDoc
   - `getStockStatus()` - Determines healthy/tight/short/critical status
   - `getStatusColors()` - Returns Tailwind classes for status (dark theme)

2. **`frontend/src/hooks/useItemDemand.js`** - React hooks
   - `useItemDemand(itemId)` - Fetches single item demand summary
   - `useMultipleItemDemands(itemIds)` - Fetches multiple items

3. **`frontend/src/components/inventory/ItemCard.jsx`** - Main component
   - Full view with quantity grid
   - Compact mode for lists
   - Shortage warnings with blocking orders
   - Allocation details with customer traceability
   - Loading skeleton
   - data-testid for E2E testing

4. **`frontend/src/components/inventory/index.js`** - Export file

### Implementation Notes

- Used JavaScript (JSX) to match existing codebase pattern (no TypeScript)
- Dark theme styling (bg-gray-900, text-gray-400) matching existing components
- Parses Decimal strings from API to numbers
- Includes auth token in API requests
- Component tests skipped (no Vitest setup in project)

---

## Why This Matters

Currently: Item displays show just a name and maybe on-hand quantity
After UI-101: Users see at a glance:
- Is this item healthy (green), tight (yellow), or short (red)?
- How much is allocated vs available?
- Quick link to see what's consuming it

This component will be reused across the app wherever items appear.

---

## Component Design

```
┌─────────────────────────────────────────────────┐
│ ● STEEL-SPRING-01                    [Details]  │
│   Spring Steel Sheet                            │
│                                                 │
│   On Hand    Allocated    Available   Incoming  │
│     45          100         -55          100    │
│                              ▲                  │
│                         (red text)              │
│                                                 │
│   ⚠️ Shortage: 55 units                         │
│   Blocking: WO-2025-0001, WO-2025-0002         │
└─────────────────────────────────────────────────┘
```

---

## Agent Types

| Agent | Role | Works In |
|-------|------|----------|
| **Frontend Agent** | React component, hooks, styling | `frontend/src/` |
| **Test Agent** | Component tests, E2E tests | `frontend/tests/` |

---

## Step-by-Step Execution

---

### Step 1 of 8: Create Type Definitions
**Agent:** Frontend Agent
**Time:** 10 minutes
**Directory:** `frontend/src/types/`

**Instruction to Agent:**
```
Create TypeScript types matching the API response.
These should mirror the Pydantic schemas from API-101.
```

**File to Create:** `frontend/src/types/itemDemand.ts`
```typescript
/**
 * Types for item demand summary API response.
 * Matches backend Pydantic schemas.
 */

export interface LinkedSalesOrder {
  id: number;
  code: string;
  customer: string;
}

export interface AllocationDetail {
  type: 'production_order' | 'work_order';
  reference_code: string;
  reference_id: number;
  quantity: number;
  needed_date: string | null;
  status: string;
  linked_sales_order: LinkedSalesOrder | null;
}

export interface IncomingDetail {
  type: 'purchase_order';
  reference_code: string;
  reference_id: number;
  quantity: number;
  expected_date: string | null;
  status: string;
  vendor: string | null;
}

export interface ShortageInfo {
  is_short: boolean;
  quantity: number;
  blocking_orders: string[];
}

export interface QuantitySummary {
  on_hand: number;
  allocated: number;
  available: number;
  incoming: number;
  projected: number;
}

export interface ItemDemandSummary {
  item_id: number;
  sku: string;
  name: string;
  quantities: QuantitySummary;
  allocations: AllocationDetail[];
  incoming: IncomingDetail[];
  shortage: ShortageInfo;
}

/**
 * Stock status for visual indicators.
 */
export type StockStatus = 'healthy' | 'tight' | 'short' | 'critical';

/**
 * Determine stock status from quantities.
 */
export function getStockStatus(quantities: QuantitySummary): StockStatus {
  const { available, on_hand } = quantities;
  
  if (available < 0) {
    return 'critical';  // Negative available = shortage
  }
  if (available === 0) {
    return 'short';     // Zero available
  }
  if (available < on_hand * 0.2) {
    return 'tight';     // Less than 20% available
  }
  return 'healthy';
}

/**
 * Get Tailwind color classes for stock status.
 */
export function getStatusColors(status: StockStatus): {
  bg: string;
  text: string;
  border: string;
  dot: string;
} {
  switch (status) {
    case 'critical':
      return {
        bg: 'bg-red-50',
        text: 'text-red-700',
        border: 'border-red-200',
        dot: 'bg-red-500'
      };
    case 'short':
      return {
        bg: 'bg-orange-50',
        text: 'text-orange-700',
        border: 'border-orange-200',
        dot: 'bg-orange-500'
      };
    case 'tight':
      return {
        bg: 'bg-yellow-50',
        text: 'text-yellow-700',
        border: 'border-yellow-200',
        dot: 'bg-yellow-500'
      };
    case 'healthy':
    default:
      return {
        bg: 'bg-green-50',
        text: 'text-green-700',
        border: 'border-green-200',
        dot: 'bg-green-500'
      };
  }
}
```

**Verification:**
- [ ] File created
- [ ] TypeScript compiles without errors

**Commit Message:** `feat(UI-101): add item demand TypeScript types`

---

### Step 2 of 8: Create API Hook
**Agent:** Frontend Agent
**Time:** 15 minutes
**Directory:** `frontend/src/hooks/`

**Instruction to Agent:**
```
Create a React hook for fetching item demand summary.
Should handle loading, error, and data states.
```

**File to Create:** `frontend/src/hooks/useItemDemand.ts`
```typescript
/**
 * Hook for fetching item demand summary.
 */
import { useState, useEffect, useCallback } from 'react';
import { ItemDemandSummary } from '../types/itemDemand';

interface UseItemDemandResult {
  data: ItemDemandSummary | null;
  loading: boolean;
  error: string | null;
  refetch: () => void;
}

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export function useItemDemand(itemId: number | null): UseItemDemandResult {
  const [data, setData] = useState<ItemDemandSummary | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchDemand = useCallback(async () => {
    if (itemId === null) {
      setData(null);
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${API_BASE}/api/v1/items/${itemId}/demand-summary`);
      
      if (!response.ok) {
        if (response.status === 404) {
          throw new Error(`Item ${itemId} not found`);
        }
        throw new Error(`Failed to fetch demand summary: ${response.statusText}`);
      }

      const result: ItemDemandSummary = await response.json();
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [itemId]);

  useEffect(() => {
    fetchDemand();
  }, [fetchDemand]);

  return { data, loading, error, refetch: fetchDemand };
}

/**
 * Hook for fetching multiple items' demand summaries.
 */
export function useMultipleItemDemands(itemIds: number[]): {
  data: Map<number, ItemDemandSummary>;
  loading: boolean;
  error: string | null;
} {
  const [data, setData] = useState<Map<number, ItemDemandSummary>>(new Map());
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (itemIds.length === 0) {
      setData(new Map());
      return;
    }

    const fetchAll = async () => {
      setLoading(true);
      setError(null);

      try {
        const results = await Promise.all(
          itemIds.map(async (id) => {
            const response = await fetch(`${API_BASE}/api/v1/items/${id}/demand-summary`);
            if (!response.ok) return null;
            return response.json() as Promise<ItemDemandSummary>;
          })
        );

        const newData = new Map<number, ItemDemandSummary>();
        results.forEach((result, index) => {
          if (result) {
            newData.set(itemIds[index], result);
          }
        });
        setData(newData);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setLoading(false);
      }
    };

    fetchAll();
  }, [itemIds.join(',')]); // Re-fetch when item list changes

  return { data, loading, error };
}
```

**Verification:**
- [ ] File created
- [ ] Hook can be imported without errors

**Commit Message:** `feat(UI-101): add useItemDemand hook`

---

### Step 3 of 8: Create ItemCard Component
**Agent:** Frontend Agent
**Time:** 30 minutes
**Directory:** `frontend/src/components/`

**Instruction to Agent:**
```
Create the ItemCard component that displays demand summary.
Use Tailwind for styling. Make it responsive and accessible.
```

**File to Create:** `frontend/src/components/inventory/ItemCard.tsx`
```typescript
/**
 * ItemCard - Displays item with demand context.
 * 
 * Shows on-hand, allocated, available quantities with visual status indicators.
 * Used throughout the app wherever items need to be displayed with demand info.
 */
import React from 'react';
import { Link } from 'react-router-dom';
import { useItemDemand } from '../../hooks/useItemDemand';
import { 
  getStockStatus, 
  getStatusColors,
  ItemDemandSummary,
  StockStatus 
} from '../../types/itemDemand';

interface ItemCardProps {
  /** Item ID to fetch demand for */
  itemId: number;
  /** Optional: Pre-fetched data (skip API call) */
  demandData?: ItemDemandSummary;
  /** Show detailed view with allocations */
  showDetails?: boolean;
  /** Compact mode for lists */
  compact?: boolean;
  /** Click handler */
  onClick?: () => void;
  /** Additional CSS classes */
  className?: string;
}

export function ItemCard({
  itemId,
  demandData,
  showDetails = false,
  compact = false,
  onClick,
  className = ''
}: ItemCardProps) {
  // Use provided data or fetch
  const { data: fetchedData, loading, error } = useItemDemand(
    demandData ? null : itemId
  );
  
  const data = demandData || fetchedData;

  if (loading) {
    return <ItemCardSkeleton compact={compact} />;
  }

  if (error || !data) {
    return (
      <div className={`p-4 border border-red-200 bg-red-50 rounded-lg ${className}`}>
        <p className="text-red-600 text-sm">
          {error || 'Failed to load item'}
        </p>
      </div>
    );
  }

  const status = getStockStatus(data.quantities);
  const colors = getStatusColors(status);

  if (compact) {
    return (
      <ItemCardCompact 
        data={data} 
        status={status} 
        colors={colors}
        onClick={onClick}
        className={className}
      />
    );
  }

  return (
    <div 
      className={`
        p-4 border rounded-lg transition-shadow hover:shadow-md
        ${colors.border} ${colors.bg} ${className}
        ${onClick ? 'cursor-pointer' : ''}
      `}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
      onKeyDown={onClick ? (e) => e.key === 'Enter' && onClick() : undefined}
    >
      {/* Header */}
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-2">
          <StatusDot status={status} />
          <div>
            <h3 className="font-semibold text-gray-900">{data.sku}</h3>
            <p className="text-sm text-gray-600">{data.name}</p>
          </div>
        </div>
        <Link 
          to={`/admin/items/${data.item_id}`}
          className="text-sm text-blue-600 hover:text-blue-800"
          onClick={(e) => e.stopPropagation()}
        >
          Details →
        </Link>
      </div>

      {/* Quantity Grid */}
      <div className="grid grid-cols-4 gap-2 mb-3">
        <QuantityBox label="On Hand" value={data.quantities.on_hand} />
        <QuantityBox label="Allocated" value={data.quantities.allocated} />
        <QuantityBox 
          label="Available" 
          value={data.quantities.available}
          highlight={data.quantities.available < 0}
          status={status}
        />
        <QuantityBox 
          label="Incoming" 
          value={data.quantities.incoming}
          muted={data.quantities.incoming === 0}
        />
      </div>

      {/* Shortage Warning */}
      {data.shortage.is_short && (
        <ShortageWarning shortage={data.shortage} />
      )}

      {/* Allocation Details (optional) */}
      {showDetails && data.allocations.length > 0 && (
        <AllocationList allocations={data.allocations} />
      )}
    </div>
  );
}

// ============================================================================
// Sub-components
// ============================================================================

function StatusDot({ status }: { status: StockStatus }) {
  const colors = getStatusColors(status);
  return (
    <span 
      className={`w-2.5 h-2.5 rounded-full ${colors.dot}`}
      aria-label={`Stock status: ${status}`}
    />
  );
}

function QuantityBox({ 
  label, 
  value, 
  highlight = false,
  muted = false,
  status
}: { 
  label: string; 
  value: number;
  highlight?: boolean;
  muted?: boolean;
  status?: StockStatus;
}) {
  const colors = status ? getStatusColors(status) : null;
  
  return (
    <div className="text-center">
      <p className="text-xs text-gray-500 uppercase tracking-wide">{label}</p>
      <p className={`
        text-lg font-semibold
        ${highlight && colors ? colors.text : ''}
        ${muted ? 'text-gray-400' : 'text-gray-900'}
      `}>
        {value.toLocaleString()}
      </p>
    </div>
  );
}

function ShortageWarning({ shortage }: { shortage: ItemDemandSummary['shortage'] }) {
  return (
    <div className="mt-3 p-2 bg-red-100 border border-red-200 rounded text-sm">
      <p className="font-medium text-red-800">
        ⚠️ Shortage: {shortage.quantity.toLocaleString()} units
      </p>
      {shortage.blocking_orders.length > 0 && (
        <p className="text-red-700 mt-1">
          Blocking: {shortage.blocking_orders.slice(0, 3).join(', ')}
          {shortage.blocking_orders.length > 3 && ` +${shortage.blocking_orders.length - 3} more`}
        </p>
      )}
    </div>
  );
}

function AllocationList({ allocations }: { allocations: ItemDemandSummary['allocations'] }) {
  return (
    <div className="mt-3 border-t pt-3">
      <h4 className="text-xs font-medium text-gray-500 uppercase mb-2">
        Allocated To
      </h4>
      <ul className="space-y-1">
        {allocations.slice(0, 5).map((alloc) => (
          <li key={alloc.reference_id} className="text-sm flex justify-between">
            <span>
              <Link 
                to={`/admin/production/${alloc.reference_id}`}
                className="text-blue-600 hover:underline"
              >
                {alloc.reference_code}
              </Link>
              {alloc.linked_sales_order && (
                <span className="text-gray-500 ml-2">
                  → {alloc.linked_sales_order.customer}
                </span>
              )}
            </span>
            <span className="text-gray-600">{alloc.quantity}</span>
          </li>
        ))}
        {allocations.length > 5 && (
          <li className="text-xs text-gray-500">
            +{allocations.length - 5} more allocations
          </li>
        )}
      </ul>
    </div>
  );
}

function ItemCardCompact({ 
  data, 
  status, 
  colors,
  onClick,
  className 
}: { 
  data: ItemDemandSummary;
  status: StockStatus;
  colors: ReturnType<typeof getStatusColors>;
  onClick?: () => void;
  className?: string;
}) {
  return (
    <div 
      className={`
        flex items-center justify-between p-2 border rounded
        ${colors.border} ${colors.bg} ${className}
        ${onClick ? 'cursor-pointer hover:shadow-sm' : ''}
      `}
      onClick={onClick}
    >
      <div className="flex items-center gap-2">
        <StatusDot status={status} />
        <span className="font-medium text-sm">{data.sku}</span>
      </div>
      <div className="flex items-center gap-4 text-sm">
        <span className="text-gray-600">{data.quantities.on_hand} on hand</span>
        <span className={`font-medium ${status === 'critical' ? colors.text : ''}`}>
          {data.quantities.available} avail
        </span>
      </div>
    </div>
  );
}

function ItemCardSkeleton({ compact }: { compact: boolean }) {
  if (compact) {
    return (
      <div className="flex items-center justify-between p-2 border rounded bg-gray-50 animate-pulse">
        <div className="flex items-center gap-2">
          <div className="w-2.5 h-2.5 rounded-full bg-gray-300" />
          <div className="h-4 w-24 bg-gray-300 rounded" />
        </div>
        <div className="h-4 w-32 bg-gray-300 rounded" />
      </div>
    );
  }

  return (
    <div className="p-4 border rounded-lg bg-gray-50 animate-pulse">
      <div className="flex items-center gap-2 mb-3">
        <div className="w-2.5 h-2.5 rounded-full bg-gray-300" />
        <div className="h-5 w-32 bg-gray-300 rounded" />
      </div>
      <div className="grid grid-cols-4 gap-2">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="text-center">
            <div className="h-3 w-12 bg-gray-300 rounded mx-auto mb-1" />
            <div className="h-6 w-16 bg-gray-300 rounded mx-auto" />
          </div>
        ))}
      </div>
    </div>
  );
}

export default ItemCard;
```

**Verification:**
- [ ] Component renders without errors
- [ ] Tailwind classes apply correctly

**Commit Message:** `feat(UI-101): add ItemCard component`

---

### Step 4 of 8: Create Component Index Export
**Agent:** Frontend Agent
**Time:** 2 minutes
**Directory:** `frontend/src/components/inventory/`

**Instruction to Agent:**
```
Create or update index file to export ItemCard.
```

**File to Create/Update:** `frontend/src/components/inventory/index.ts`
```typescript
export { ItemCard } from './ItemCard';
export { default as ItemCardDefault } from './ItemCard';
```

**Verification:**
- [ ] `import { ItemCard } from '@/components/inventory'` works

**Commit Message:** `chore(UI-101): export ItemCard from index`

---

### Step 5 of 8: Write Component Tests
**Agent:** Test Agent
**Time:** 20 minutes
**Directory:** `frontend/src/components/inventory/`

**Instruction to Agent:**
```
Create component tests for ItemCard.
Test rendering, loading state, error state, and interactivity.
```

**File to Create:** `frontend/src/components/inventory/ItemCard.test.tsx`
```typescript
/**
 * Tests for ItemCard component.
 */
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { ItemCard } from './ItemCard';
import { ItemDemandSummary } from '../../types/itemDemand';

// Mock fetch
const mockFetch = vi.fn();
global.fetch = mockFetch;

// Wrapper with router
const Wrapper = ({ children }: { children: React.ReactNode }) => (
  <BrowserRouter>{children}</BrowserRouter>
);

// Sample data
const mockDemandData: ItemDemandSummary = {
  item_id: 123,
  sku: 'TEST-SKU-001',
  name: 'Test Item',
  quantities: {
    on_hand: 100,
    allocated: 30,
    available: 70,
    incoming: 50,
    projected: 120
  },
  allocations: [
    {
      type: 'production_order',
      reference_code: 'WO-2025-0001',
      reference_id: 1,
      quantity: 30,
      needed_date: '2025-01-15',
      status: 'released',
      linked_sales_order: {
        id: 1,
        code: 'SO-2025-0001',
        customer: 'Acme Corp'
      }
    }
  ],
  incoming: [],
  shortage: {
    is_short: false,
    quantity: 0,
    blocking_orders: []
  }
};

const mockShortageData: ItemDemandSummary = {
  ...mockDemandData,
  quantities: {
    on_hand: 30,
    allocated: 80,
    available: -50,
    incoming: 100,
    projected: 50
  },
  shortage: {
    is_short: true,
    quantity: 50,
    blocking_orders: ['WO-2025-0001', 'WO-2025-0002']
  }
};

describe('ItemCard', () => {
  beforeEach(() => {
    mockFetch.mockReset();
  });

  describe('with pre-fetched data', () => {
    it('renders item details correctly', () => {
      render(
        <Wrapper>
          <ItemCard itemId={123} demandData={mockDemandData} />
        </Wrapper>
      );

      expect(screen.getByText('TEST-SKU-001')).toBeInTheDocument();
      expect(screen.getByText('Test Item')).toBeInTheDocument();
    });

    it('displays all quantity fields', () => {
      render(
        <Wrapper>
          <ItemCard itemId={123} demandData={mockDemandData} />
        </Wrapper>
      );

      expect(screen.getByText('On Hand')).toBeInTheDocument();
      expect(screen.getByText('100')).toBeInTheDocument();
      expect(screen.getByText('Allocated')).toBeInTheDocument();
      expect(screen.getByText('30')).toBeInTheDocument();
      expect(screen.getByText('Available')).toBeInTheDocument();
      expect(screen.getByText('70')).toBeInTheDocument();
    });

    it('shows shortage warning when short', () => {
      render(
        <Wrapper>
          <ItemCard itemId={123} demandData={mockShortageData} />
        </Wrapper>
      );

      expect(screen.getByText(/Shortage: 50 units/)).toBeInTheDocument();
      expect(screen.getByText(/Blocking:/)).toBeInTheDocument();
    });

    it('shows allocation details when showDetails=true', () => {
      render(
        <Wrapper>
          <ItemCard itemId={123} demandData={mockDemandData} showDetails />
        </Wrapper>
      );

      expect(screen.getByText('Allocated To')).toBeInTheDocument();
      expect(screen.getByText('WO-2025-0001')).toBeInTheDocument();
      expect(screen.getByText(/Acme Corp/)).toBeInTheDocument();
    });

    it('renders compact mode correctly', () => {
      render(
        <Wrapper>
          <ItemCard itemId={123} demandData={mockDemandData} compact />
        </Wrapper>
      );

      expect(screen.getByText('TEST-SKU-001')).toBeInTheDocument();
      expect(screen.getByText('100 on hand')).toBeInTheDocument();
      expect(screen.getByText('70 avail')).toBeInTheDocument();
    });
  });

  describe('with API fetch', () => {
    it('shows loading state', async () => {
      mockFetch.mockImplementation(() => new Promise(() => {})); // Never resolves

      render(
        <Wrapper>
          <ItemCard itemId={123} />
        </Wrapper>
      );

      // Should show skeleton
      expect(document.querySelector('.animate-pulse')).toBeInTheDocument();
    });

    it('fetches and displays data', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockDemandData
      });

      render(
        <Wrapper>
          <ItemCard itemId={123} />
        </Wrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('TEST-SKU-001')).toBeInTheDocument();
      });
    });

    it('shows error on fetch failure', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Server Error'
      });

      render(
        <Wrapper>
          <ItemCard itemId={123} />
        </Wrapper>
      );

      await waitFor(() => {
        expect(screen.getByText(/Failed to fetch/)).toBeInTheDocument();
      });
    });

    it('shows not found for 404', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 404
      });

      render(
        <Wrapper>
          <ItemCard itemId={99999} />
        </Wrapper>
      );

      await waitFor(() => {
        expect(screen.getByText(/not found/i)).toBeInTheDocument();
      });
    });
  });

  describe('interactivity', () => {
    it('calls onClick when clicked', async () => {
      const handleClick = vi.fn();

      render(
        <Wrapper>
          <ItemCard itemId={123} demandData={mockDemandData} onClick={handleClick} />
        </Wrapper>
      );

      screen.getByRole('button').click();
      expect(handleClick).toHaveBeenCalledTimes(1);
    });

    it('has details link', () => {
      render(
        <Wrapper>
          <ItemCard itemId={123} demandData={mockDemandData} />
        </Wrapper>
      );

      const link = screen.getByText('Details →');
      expect(link).toHaveAttribute('href', '/admin/items/123');
    });
  });

  describe('stock status colors', () => {
    it('shows green for healthy stock', () => {
      render(
        <Wrapper>
          <ItemCard itemId={123} demandData={mockDemandData} />
        </Wrapper>
      );

      const card = screen.getByText('TEST-SKU-001').closest('div');
      expect(card?.className).toContain('bg-green');
    });

    it('shows red for critical shortage', () => {
      render(
        <Wrapper>
          <ItemCard itemId={123} demandData={mockShortageData} />
        </Wrapper>
      );

      const card = screen.getByText('TEST-SKU-001').closest('div')?.parentElement;
      expect(card?.className).toContain('bg-red');
    });
  });
});
```

**Verification:**
- [ ] Tests run with `npm run test`
- [ ] All tests pass

**Commit Message:** `test(UI-101): add ItemCard component tests`

---

### Step 6 of 8: Create E2E Test Fragment
**Agent:** Test Agent
**Time:** 15 minutes
**Directory:** `frontend/tests/e2e/`

**Instruction to Agent:**
```
Create E2E test that verifies ItemCard renders with seeded data.
This will be combined with other tests later for full flow testing.
```

**File to Create:** `frontend/tests/e2e/pages/item-card.spec.ts`
```typescript
/**
 * E2E tests for ItemCard component.
 */
import { test, expect } from '@playwright/test';
import { seedTestScenario, cleanupTestData, login } from '../fixtures/test-utils';

test.describe('ItemCard Component', () => {
  test.beforeEach(async () => {
    await seedTestScenario('full-demand-chain');
  });

  test.afterEach(async () => {
    await cleanupTestData();
  });

  test('displays item with demand context on inventory page', async ({ page }) => {
    await login(page);
    
    // Navigate to inventory/items page
    await page.goto('/admin/items');
    
    // Find the steel item card (from seeded data)
    const steelCard = page.locator('[data-testid="item-card"]').filter({
      hasText: 'STEEL-SPRING-01'
    });
    
    // Should show the SKU
    await expect(steelCard.getByText('STEEL-SPRING-01')).toBeVisible();
    
    // Should show quantities
    await expect(steelCard.getByText('On Hand')).toBeVisible();
    await expect(steelCard.getByText('45')).toBeVisible(); // From scenario
    
    // Should show shortage indicator (steel is short in this scenario)
    await expect(steelCard.getByText(/Shortage/)).toBeVisible();
  });

  test('item card links to detail page', async ({ page }) => {
    await login(page);
    await page.goto('/admin/items');
    
    // Find item card and click details link
    const steelCard = page.locator('[data-testid="item-card"]').filter({
      hasText: 'STEEL-SPRING-01'
    });
    
    await steelCard.getByText('Details →').click();
    
    // Should navigate to item detail page
    await expect(page).toHaveURL(/\/admin\/items\/\d+/);
  });

  test('shows linked sales order in allocation details', async ({ page }) => {
    await login(page);
    await page.goto('/admin/items');
    
    // Find item card with allocations visible
    const steelCard = page.locator('[data-testid="item-card"]').filter({
      hasText: 'STEEL-SPRING-01'
    });
    
    // If showDetails is enabled, should see allocation info
    // Check for the linked customer name
    await expect(steelCard.getByText(/Acme Corporation/)).toBeVisible();
  });

  test('color indicates stock status', async ({ page }) => {
    await login(page);
    await page.goto('/admin/items');
    
    // Steel item should be red (shortage)
    const steelCard = page.locator('[data-testid="item-card"]').filter({
      hasText: 'STEEL-SPRING-01'
    });
    
    // Card should have red background class
    await expect(steelCard).toHaveClass(/bg-red/);
  });
});
```

**Note:** These tests assume the items page uses ItemCard. Adjust selectors based on actual page implementation.

**Verification:**
- [ ] Tests run (may fail if page not yet implemented - that's OK)

**Commit Message:** `test(UI-101): add ItemCard E2E tests`

---

### Step 7 of 8: Add data-testid Attribute
**Agent:** Frontend Agent
**Time:** 5 minutes
**Directory:** `frontend/src/components/inventory/`

**Instruction to Agent:**
```
Add data-testid to ItemCard for E2E test selection.
```

**Update:** `frontend/src/components/inventory/ItemCard.tsx`
```typescript
// Add to the main div:
<div 
  data-testid="item-card"
  className={`...`}
>
```

**Verification:**
- [ ] data-testid appears in rendered HTML

**Commit Message:** `chore(UI-101): add data-testid to ItemCard`

---

### Step 8 of 8: Document Component Usage
**Agent:** Frontend Agent
**Time:** 10 minutes
**Directory:** `frontend/src/components/inventory/`

**Instruction to Agent:**
```
Add JSDoc comments and create a README or Storybook story.
```

**Optional - Create Storybook story:** `frontend/src/components/inventory/ItemCard.stories.tsx`
```typescript
import type { Meta, StoryObj } from '@storybook/react';
import { ItemCard } from './ItemCard';

const meta: Meta<typeof ItemCard> = {
  title: 'Inventory/ItemCard',
  component: ItemCard,
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof ItemCard>;

export const Healthy: Story = {
  args: {
    itemId: 1,
    demandData: {
      item_id: 1,
      sku: 'WIDGET-01',
      name: 'Widget Assembly',
      quantities: {
        on_hand: 100,
        allocated: 20,
        available: 80,
        incoming: 0,
        projected: 80
      },
      allocations: [],
      incoming: [],
      shortage: { is_short: false, quantity: 0, blocking_orders: [] }
    }
  }
};

export const Shortage: Story = {
  args: {
    itemId: 2,
    demandData: {
      item_id: 2,
      sku: 'STEEL-SPRING-01',
      name: 'Spring Steel Sheet',
      quantities: {
        on_hand: 45,
        allocated: 100,
        available: -55,
        incoming: 100,
        projected: 45
      },
      allocations: [
        {
          type: 'production_order',
          reference_code: 'WO-2025-0001',
          reference_id: 1,
          quantity: 100,
          needed_date: '2025-01-15',
          status: 'released',
          linked_sales_order: {
            id: 1,
            code: 'SO-2025-0001',
            customer: 'Acme Corporation'
          }
        }
      ],
      incoming: [
        {
          type: 'purchase_order',
          reference_code: 'PUR-2025-0001',
          reference_id: 1,
          quantity: 100,
          expected_date: '2025-01-10',
          status: 'ordered',
          vendor: 'Amazon Business'
        }
      ],
      shortage: {
        is_short: true,
        quantity: 55,
        blocking_orders: ['WO-2025-0001']
      }
    }
  }
};

export const Compact: Story = {
  args: {
    ...Healthy.args,
    compact: true
  }
};

export const WithDetails: Story = {
  args: {
    ...Shortage.args,
    showDetails: true
  }
};
```

**Verification:**
- [ ] Component is documented
- [ ] Storybook shows component (if using Storybook)

**Commit Message:** `docs(UI-101): add ItemCard documentation`

---

## Final Checklist

- [ ] TypeScript types created
- [ ] useItemDemand hook created
- [ ] ItemCard component created
- [ ] Component exported from index
- [ ] Component tests pass
- [ ] E2E test fragment created
- [ ] data-testid added
- [ ] Documentation complete

---

## Component Usage

After UI-101, use ItemCard anywhere items appear:

```tsx
// Basic usage
<ItemCard itemId={123} />

// With pre-fetched data (avoids extra API call)
<ItemCard itemId={123} demandData={fetchedData} />

// In a list (compact mode)
{items.map(item => (
  <ItemCard key={item.id} itemId={item.id} compact />
))}

// With full details
<ItemCard itemId={123} showDetails />

// Clickable
<ItemCard itemId={123} onClick={() => setSelectedItem(123)} />
```

---

## Handoff to Next Ticket

**E2E-101: Full Demand Pegging Flow Test**
- Combines API-101 + UI-101
- Tests complete flow from low stock to sales order visibility

---

## Notes for Agents

1. **Match actual routes** - Adjust Link `to` props to match your routing
2. **Tailwind must be configured** - Ensure Tailwind classes work
3. **Test data-testid** - E2E tests rely on these
4. **Check API URL** - Update hook if API base URL differs
5. **React Router required** - Links use react-router-dom
