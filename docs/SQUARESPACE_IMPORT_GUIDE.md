# Squarespace Import Guide

This guide explains how to export and import products and customers from Squarespace into FilaOps.

---

## Exporting from Squarespace

### Products Export

1. **Log into Squarespace**
   - Go to your Squarespace admin panel
   - Navigate to **Commerce** → **Inventory**

2. **Export Products**
   - Click the **Export** button (usually top right)
   - Select **CSV Export**
   - Download the file

3. **Squarespace Product CSV Format**
   Squarespace exports products with these columns:
   - `SKU` (maps to `sku`) - **Required**
   - `Title` or `Product Name` (maps to `name`) - **Required**
   - `Description` (maps to `description`) - Optional
   - `Price` (maps to `selling_price`) - Optional
   - `Quantity` (for inventory) - Optional
   - `Weight` (optional)
   - `Category` (optional)

### Customers Export

**Important:** Squarespace doesn't have a direct "customers" export. You need to export **orders** and extract customer information from them.

1. **Export Orders**
   - Go to **Commerce** → **Orders**
   - Click **Export** → **CSV**
   - This exports all orders with customer information

2. **Squarespace Order CSV Format**
   Squarespace order exports include:
   - `Email` (customer email) - **Required**
   - `Shipping Name` (full name - will be split into first/last)
   - `Shipping Address Line 1`
   - `Shipping City`
   - `Shipping State`
   - `Shipping Postal Code`
   - `Shipping Country`
   - `Billing Name` (optional)
   - `Billing Address` (optional)
   - `Phone` (optional)

---

## Importing into FilaOps

### Products Import

**Good News:** FilaOps now automatically recognizes Squarespace column names!

**Supported Squarespace Columns:**
- `SKU` → automatically mapped to `sku`
- `Title` or `Product Name` → automatically mapped to `name`
- `Description` → automatically mapped to `description`
- `Price` → automatically mapped to `selling_price` (handles $ signs)
- `Cost` or `Wholesale Price` → automatically mapped to `standard_cost`

**Step 1: Export from Squarespace**
- Export your products CSV as normal
- No need to modify column names!

**Step 2: Import into FilaOps**
1. Go to **Products** → **Import** (or use onboarding wizard)
2. Select your Squarespace CSV file
3. Review errors (if any)
4. Fix errors and re-import if needed

**Common Issues:**

**Issue: "SKU is required" errors**
- **Problem:** Some products in Squarespace might not have SKUs
- **Solution:** 
  - Filter out rows with empty SKUs before importing
  - Or add SKUs in Squarespace first
  - Or generate SKUs: Use product name + number (e.g., "Widget" → "WIDGET-001")

**Issue: "Name is required" errors**
- **Problem:** Product name column might be empty
- **Solution:** 
  - Check your CSV has a "Title" or "Product Name" column
  - Fill in missing names in Squarespace before exporting

**Issue: Price format errors**
- **Problem:** Prices might have $ signs or commas
- **Solution:** FilaOps now automatically handles this! But if you still see errors:
  - Remove $ signs manually: `$19.99` → `19.99`
  - Remove commas: `1,000` → `1000`

### Customers Import

**Step 1: Export Orders from Squarespace**
1. Go to **Commerce** → **Orders**
2. Click **Export** → **CSV**
3. Download the orders CSV

**Step 2: Extract Unique Customers**

Since Squarespace exports orders (not customers), you need to extract unique customers:

**Option A: Use Excel/Google Sheets**
1. Open the orders CSV
2. Remove duplicate emails (Data → Remove Duplicates)
3. Keep one row per unique email
4. Save as a new CSV

**Option B: Use the CSV directly**
FilaOps will automatically:
- Extract unique customers from the orders CSV
- Map Squarespace columns to customer fields
- Skip duplicate emails

**Step 3: Import into FilaOps**

1. Go to **Customers** → **Import** (or use onboarding wizard)
2. Select your Squarespace orders CSV
3. FilaOps will automatically:
   - Detect it's from Squarespace
   - Map "Shipping Name" to first_name/last_name
   - Map shipping address fields
   - Extract unique customers

**Supported Squarespace Customer Columns:**
- `Email` → `email` (required)
- `Shipping Name` → automatically split into `first_name` and `last_name`
- `Shipping Address Line 1` → `shipping_address_line1`
- `Shipping City` → `shipping_city`
- `Shipping State` → `shipping_state`
- `Shipping Postal Code` → `shipping_zip`
- `Shipping Country` → `shipping_country`
- `Phone` → `phone`

**Common Issues:**

**Issue: "Failed to fetch" error**
- **Problem:** Network error or wrong CSV format
- **Solutions:**
  1. **Check CSV format:**
     - Must have `Email` column
     - Must be valid CSV (not Excel .xlsx)
     - File size under 10MB
  
  2. **Check network:**
     - Ensure backend is running
     - Check browser console (F12) for errors
     - Try smaller file first (10-20 rows)
  
  3. **Use preview first:**
     - The import endpoint now has better error handling
     - Check the error messages - they tell you exactly what's wrong

**Issue: Duplicate emails**
- **Problem:** Same customer appears multiple times in orders
- **Solution:** 
  - FilaOps automatically skips duplicate emails
  - Or use Excel's "Remove Duplicates" before importing
  - Keep the most recent order's address

---

## Quick Reference

### Minimum Product CSV (Squarespace format)
```csv
SKU,Title
PROD-001,My Product
PROD-002,Another Product
```

### Minimum Customer CSV (from Orders export)
```csv
Email,Shipping Name
customer@example.com,John Doe
```

### Full Product CSV Example (Squarespace format)
```csv
SKU,Title,Description,Price,Cost
PROD-001,Widget,Great widget,$19.99,$10.00
PROD-002,Gadget,Amazing gadget,$29.99,$15.00
```

### Full Customer CSV Example (from Orders export)
```csv
Email,Shipping Name,Shipping Address Line 1,Shipping City,Shipping State,Shipping Postal Code,Shipping Country,Phone
john@example.com,John Doe,123 Main St,Anytown,CA,12345,USA,555-1234
jane@example.com,Jane Smith,456 Oak Ave,Somewhere,NY,67890,USA,555-5678
```

---

## Tips

1. **Start Small:** Test with 5-10 products/customers first
2. **Check Errors:** Review error messages - they tell you exactly what's wrong
3. **Fix in Squarespace:** It's easier to fix data in Squarespace before exporting
4. **Use Preview:** The customer import has a preview endpoint to check data before importing
5. **Backup First:** Always backup your database before large imports

---

## Need Help?

- Check the error messages - they're very specific
- Start with a small test file (5-10 rows) to verify format
- Review the import results - they show exactly what was imported vs skipped
- Contact support if you're stuck!
