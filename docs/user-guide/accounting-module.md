# Accounting Module User Guide

## Overview

The Accounting Module provides financial visibility into your 3D print farm operations. It automatically creates GL journal entries for inventory transactions, ensuring your books stay in sync with physical operations.

## Accessing the Module

1. Navigate to **Admin** → **Accounting**
2. Requires **Pro** or **Enterprise** tier for GL Reports and Period Management

## Available Reports

### GL Reports Tab

#### Trial Balance
Shows all General Ledger account balances as of a specific date.

- **Debit Balance**: Normal for Assets (1xxx) and Expenses (5xxx)
- **Credit Balance**: Normal for Liabilities (2xxx) and Revenue (4xxx)
- **Is Balanced**: ✓ means total debits = total credits (healthy books)

**Tip:** Click any account row to view its transaction ledger. If books are unbalanced, check for incomplete transactions or manual adjustments.

#### Inventory Valuation
Compares physical inventory value to GL account balances.

| Category | GL Account | Description |
|----------|------------|-------------|
| Raw Materials | 1200 | Filament, components |
| WIP | 1210 | In-progress production |
| Finished Goods | 1220 | Completed products |
| Packaging | 1230 | Boxes, labels |

**Variance** indicates a discrepancy between what's physically on hand and what's recorded in the GL. Common causes:
- Manual inventory adjustments without GL entry
- Incomplete transactions
- Timing differences
- Inventory that existed before GL system was implemented

#### Transaction Ledger
Detailed transaction history for a specific GL account.

- Enter an account code (e.g., 1200) to view all journal entries affecting that account
- Shows running balance after each transaction
- Links back to source documents (PO, SO, Production Order)

### Periods Tab

Manage fiscal periods to control when entries can be posted.

#### Closing a Period
1. Click **Close** on an open period
2. System validates all entries are balanced
3. Once closed, no new entries can be backdated to that period

#### Reopening a Period
- Use with caution - allows modifications to historical data
- Typically used to correct errors discovered after close
- Requires admin privileges

## GL Account Reference

| Code | Name | Type | Normal Balance |
|------|------|------|----------------|
| 1200 | Raw Materials Inventory | Asset | Debit |
| 1210 | Work in Process | Asset | Debit |
| 1220 | Finished Goods Inventory | Asset | Debit |
| 1230 | Packaging Inventory | Asset | Debit |
| 2000 | Accounts Payable | Liability | Credit |
| 5000 | Cost of Goods Sold | Expense | Debit |
| 5010 | Shipping Expense | Expense | Debit |
| 5020 | Scrap Expense | Expense | Debit |
| 5030 | Inventory Adjustment | Expense | Debit |

## Transaction Flow

### Purchase Order Receipt
```
DR 1200 Raw Materials
   CR 2000 Accounts Payable
```

### Material Issue to Production
```
DR 1210 WIP
   CR 1200 Raw Materials
```

### Finished Goods Receipt (QC Pass)
```
DR 1220 Finished Goods
   CR 1210 WIP
```

### Shipment to Customer
```
DR 5000 COGS
   CR 1220 Finished Goods
DR 5010 Shipping Expense
   CR 1230 Packaging
```

### Scrap (QC Fail)
```
DR 5020 Scrap Expense
   CR 1210 WIP
```

## Troubleshooting

### Books Not Balanced
1. Check Trial Balance for the variance amount
2. Use Transaction Ledger to find recent entries
3. Look for entries with only one side (missing DR or CR)

### Inventory Valuation Variance
1. Compare physical count to system on-hand
2. Check for manual inventory adjustments
3. Verify all PO receipts have been recorded
4. Note: Inventory that existed before the GL system was implemented will show as variance

### Cannot Post Entry to Closed Period
1. Check Periods tab for period status
2. If needed, reopen the period (admin only)
3. Post entry, then re-close period

## Tier Differences

| Feature | Community | Pro | Enterprise |
|---------|-----------|-----|------------|
| Basic Inventory | ✓ | ✓ | ✓ |
| GL Reports | - | ✓ | ✓ |
| Period Management | - | ✓ | ✓ |
| Transaction Ledger | - | ✓ | ✓ |
| Audit Trail | - | - | ✓ |

## Dashboard Widgets

The Accounting Dashboard provides a quick overview:

- **Total Inventory Value**: Sum of all inventory categories
- **Inventory by Category**: Breakdown by Raw Materials, WIP, Finished Goods, Packaging
- **Current Period**: Active fiscal period with status
- **Entry Activity**: Counts for today, this week, and this month
- **Books Balanced**: Quick indicator if DR = CR
- **Recent Entries**: Last 10 journal entries with amounts
