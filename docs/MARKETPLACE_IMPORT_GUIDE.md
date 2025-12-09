# Marketplace Import Guide

Complete guide for importing products and customers from all major e-commerce platforms into FilaOps.

**FilaOps automatically detects and adapts to all marketplace CSV formats!** No manual column mapping needed.

---

## Supported Marketplaces

FilaOps supports imports from:
- ✅ **Squarespace** - Full product and customer support
- ✅ **Shopify** - Full product and customer support
- ✅ **WooCommerce** - Full product and customer support
- ✅ **Etsy** - Customer support (from orders)
- ✅ **TikTok Shop** - Full product and customer support
- ✅ **Amazon** (Business orders) - Product and customer support
- ✅ **Generic CSV** - Any platform with standard columns

**See [Marketplace Column Reference](./MARKETPLACE_COLUMN_REFERENCE.md) for complete column mapping details.**

---

## Table of Contents

1. [Squarespace](#squarespace)
2. [Shopify](#shopify)
3. [WooCommerce](#woocommerce)
4. [Etsy](#etsy)
5. [TikTok Shop](#tiktok-shop)
6. [Amazon](#amazon)
7. [Generic CSV](#generic-csv)
8. [Common Issues & Solutions](#common-issues--solutions)

---

## Squarespace

### Products Export

**Steps:**
1. Log into Squarespace admin
2. Go to **Commerce** → **Inventory**
3. Click **Export** → **CSV Export**
4. Download the file

**Squarespace Product CSV Columns:**
- `SKU` (required) - Product SKU
- `Title` or `Product Name` (required) - Product name
- `Description` - Product description
- `Price` - Selling price (may include $ sign)
- `Cost` or `Wholesale Price` - Cost (optional)
- `Quantity` - Stock quantity
- `Weight` - Product weight
- `Category` - Product category

**FilaOps Auto-Mapping:**
- `SKU` → `sku`
- `Title` / `Product Name` → `name`
- `Description` → `description`
- `Price` → `selling_price` (handles $ signs automatically)
- `Cost` / `Wholesale Price` → `standard_cost`

**Import:**
1. Go to **Products** → **Import**
2. Select your Squarespace CSV
3. No column renaming needed - FilaOps recognizes Squarespace format!

### Customers Export

**Important:** Squarespace doesn't export customers directly. Export **orders** instead.

**Steps:**
1. Go to **Commerce** → **Orders**
2. Click **Export** → **CSV**
3. Download orders CSV

**Squarespace Order CSV Columns:**
- `Email` (required) - Customer email
- `Shipping Name` - Full name (auto-split into first/last)
- `Shipping Address Line 1`
- `Shipping City`
- `Shipping State`
- `Shipping Postal Code`
- `Shipping Country`
- `Phone` (optional)
- `Billing Name` (optional)
- `Billing Address` (optional)

**FilaOps Auto-Mapping:**
- `Email` → `email`
- `Shipping Name` → `first_name` + `last_name` (auto-split)
- `Shipping Address Line 1` → `shipping_address_line1`
- `Shipping City` → `shipping_city`
- `Shipping State` → `shipping_state`
- `Shipping Postal Code` → `shipping_zip`
- `Shipping Country` → `shipping_country`
- `Phone` → `phone`

**Import:**
1. Go to **Customers** → **Import**
2. Select your Squarespace orders CSV
3. FilaOps automatically extracts unique customers from orders

**Note:** Duplicate emails are automatically skipped (one customer per email).

---

## Shopify

### Products Export

**Steps:**
1. Log into Shopify admin
2. Go to **Products**
3. Click **Export** (top right)
4. Select **Export all products**
5. Click **Export products**
6. Download CSV when ready

**Shopify Product CSV Columns:**
- `Handle` - URL slug (not used)
- `Title` (required) - Product name
- `Body (HTML)` - Description
- `Vendor` - Brand/manufacturer
- `Type` - Product type
- `Tags` - Product tags
- `Published` - Published status
- `Option1 Name` - Variant option name
- `Option1 Value` - Variant option value
- `Variant SKU` (required) - Product SKU
- `Variant Price` - Selling price
- `Variant Compare At Price` - Original price
- `Variant Cost` - Cost
- `Variant Inventory Qty` - Stock quantity
- `Variant Weight` - Weight
- `Image Src` - Product image URL

**FilaOps Auto-Mapping:**
- `Variant SKU` → `sku`
- `Title` → `name`
- `Body (HTML)` → `description` (HTML stripped)
- `Variant Price` → `selling_price`
- `Variant Cost` → `standard_cost`
- `Variant Weight` → `weight_oz`

**Import:**
1. Go to **Products** → **Import**
2. Select your Shopify CSV
3. FilaOps recognizes Shopify format automatically

**Note:** Shopify exports variants as separate rows. Each variant becomes a separate product in FilaOps.

### Customers Export

**Steps:**
1. Go to **Customers**
2. Click **Export** (top right)
3. Select **Export all customers**
4. Click **Export customers**
5. Download CSV when ready

**Shopify Customer CSV Columns:**
- `First Name`
- `Last Name`
- `Email` (required)
- `Company`
- `Address1`
- `Address2`
- `City`
- `Province` or `Province Code`
- `Zip` or `Postal Code`
- `Country` or `Country Code`
- `Phone`
- `Accepts Marketing`
- `Total Spent`
- `Total Orders`

**FilaOps Auto-Mapping:**
- `Email` → `email`
- `First Name` → `first_name`
- `Last Name` → `last_name`
- `Company` → `company_name`
- `Address1` → `billing_address_line1` and `shipping_address_line1`
- `Address2` → `billing_address_line2` and `shipping_address_line2`
- `City` → `billing_city` and `shipping_city`
- `Province` / `Province Code` → `billing_state` and `shipping_state`
- `Zip` / `Postal Code` → `billing_zip` and `shipping_zip`
- `Country` / `Country Code` → `billing_country` and `shipping_country`
- `Phone` → `phone`

**Import:**
1. Go to **Customers** → **Import**
2. Select your Shopify customers CSV
3. FilaOps automatically maps all fields

---

## WooCommerce

### Products Export

**Steps:**
1. Log into WordPress admin
2. Go to **WooCommerce** → **Products**
3. Click **Export** (top right)
4. Select **Export all products**
5. Click **Export**
6. Download CSV

**WooCommerce Product CSV Columns:**
- `SKU` (required) - Product SKU
- `Name` (required) - Product name
- `Description` - Product description
- `Short description` - Short description
- `Regular price` - Selling price
- `Sale price` - Sale price (if on sale)
- `Stock` - Stock quantity
- `Weight` - Product weight
- `Categories` - Product categories (comma-separated)
- `Tags` - Product tags (comma-separated)
- `Type` - Product type (simple, variable, etc.)

**FilaOps Auto-Mapping:**
- `SKU` → `sku`
- `Name` → `name`
- `Description` → `description`
- `Regular price` → `selling_price`
- `Weight` → `weight_oz`

**Import:**
1. Go to **Products** → **Import**
2. Select your WooCommerce CSV
3. FilaOps recognizes WooCommerce format

**Note:** If product has `Sale price`, use that as `selling_price` instead of `Regular price`.

### Customers Export

**Steps:**
1. Go to **WooCommerce** → **Customers**
2. Click **Export** (top right)
3. Select **Export all customers**
4. Click **Export**
5. Download CSV

**WooCommerce Customer CSV Columns:**
- `Email` (required) - Customer email
- `Billing First Name`
- `Billing Last Name`
- `Billing Company`
- `Billing Address 1`
- `Billing Address 2`
- `Billing City`
- `Billing State`
- `Billing Postcode`
- `Billing Country`
- `Billing Phone`
- `Shipping First Name`
- `Shipping Last Name`
- `Shipping Company`
- `Shipping Address 1`
- `Shipping Address 2`
- `Shipping City`
- `Shipping State`
- `Shipping Postcode`
- `Shipping Country`

**FilaOps Auto-Mapping:**
- `Email` → `email`
- `Billing First Name` → `first_name`
- `Billing Last Name` → `last_name`
- `Billing Company` → `company_name`
- `Billing Address 1` → `billing_address_line1`
- `Billing Address 2` → `billing_address_line2`
- `Billing City` → `billing_city`
- `Billing State` → `billing_state`
- `Billing Postcode` → `billing_zip`
- `Billing Country` → `billing_country`
- `Billing Phone` → `phone`
- `Shipping Address 1` → `shipping_address_line1`
- `Shipping Address 2` → `shipping_address_line2`
- `Shipping City` → `shipping_city`
- `Shipping State` → `shipping_state`
- `Shipping Postcode` → `shipping_zip`
- `Shipping Country` → `shipping_country`

**Import:**
1. Go to **Customers** → **Import**
2. Select your WooCommerce customers CSV
3. FilaOps automatically maps all billing and shipping fields

---

## Etsy

### Products Export

**Note:** Etsy doesn't have a direct product export. You'll need to:
1. Use Etsy API (if available)
2. Or manually create products
3. Or export from your Etsy orders

### Customers Export

**Steps:**
1. Go to **Shop Manager** → **Orders**
2. Click **Download** (top right)
3. Select date range
4. Click **Download CSV**
5. Download orders CSV

**Etsy Order CSV Columns:**
- `Buyer Name` - Full name (auto-split)
- `Buyer Email` (required) - Customer email
- `Ship Name` - Shipping name (if different)
- `Ship Address 1`
- `Ship Address 2`
- `Ship City`
- `Ship State`
- `Ship Zipcode`
- `Ship Country`
- `Ship Phone Number`

**FilaOps Auto-Mapping:**
- `Buyer Email` → `email`
- `Buyer Name` → `first_name` + `last_name` (auto-split)
- `Ship Name` → `shipping_name` (if different from buyer)
- `Ship Address 1` → `shipping_address_line1`
- `Ship Address 2` → `shipping_address_line2`
- `Ship City` → `shipping_city`
- `Ship State` → `shipping_state`
- `Ship Zipcode` → `shipping_zip`
- `Ship Country` → `shipping_country`
- `Ship Phone Number` → `phone`

**Import:**
1. Go to **Customers** → **Import**
2. Select your Etsy orders CSV
3. FilaOps automatically extracts unique customers

**Note:** Etsy exports orders, not customers. FilaOps automatically deduplicates by email.

---

## Amazon

### Products Export

**Note:** Amazon doesn't export your product catalog directly. Options:
1. Export from Amazon Seller Central inventory reports
2. Use Amazon API (if available)
3. Manually create products

### Customers Export

**Note:** Amazon doesn't provide customer information for privacy reasons. You can only export:
- Order information (without customer details)
- Business purchase orders (if using Amazon Business)

**For Amazon Business Orders:**
1. Go to **Amazon Business** → **Orders**
2. Export order reports
3. Use the order CSV (limited customer info available)

**Amazon Business Order CSV Columns:**
- `Buyer Email` (if available)
- `Buyer Name`
- `Ship To Address`
- `Ship To City`
- `Ship To State`
- `Ship To Zip`
- `Ship To Country`

**FilaOps Auto-Mapping:**
- `Buyer Email` → `email`
- `Buyer Name` → `first_name` + `last_name` (auto-split)
- `Ship To Address` → `shipping_address_line1`
- `Ship To City` → `shipping_city`
- `Ship To State` → `shipping_state`
- `Ship To Zip` → `shipping_zip`
- `Ship To Country` → `shipping_country`

**Import:**
1. Go to **Customers** → **Import**
2. Select your Amazon Business orders CSV
3. FilaOps extracts customer information (if available)

**Note:** Amazon Business may not include customer emails for privacy. You may need to manually add customer information.

---

## Generic CSV

If your platform isn't listed above, you can still import using a generic CSV format.

### Products CSV Format

**Required Columns:**
- `sku` (required) - Product SKU
- `name` (required) - Product name

**Optional Columns:**
- `description` - Product description
- `selling_price` - Selling price (numbers only, no $ signs)
- `standard_cost` - Cost (numbers only)
- `unit` - Unit of measure (EA, KG, etc.) - default: EA
- `item_type` - Type: finished_good, component, supply, service - default: finished_good
- `category_id` - Category ID (if using categories)
- `reorder_point` - Reorder point quantity
- `upc` - UPC/barcode

**Example:**
```csv
sku,name,description,selling_price,standard_cost,unit,item_type
PROD-001,Widget,Great widget,19.99,10.00,EA,finished_good
PROD-002,Gadget,Amazing gadget,29.99,15.00,EA,finished_good
```

### Customers CSV Format

**Required Columns:**
- `email` (required) - Customer email

**Optional Columns:**
- `first_name` - First name
- `last_name` - Last name
- `company_name` - Company name
- `phone` - Phone number
- `billing_address_line1` - Billing address line 1
- `billing_address_line2` - Billing address line 2
- `billing_city` - Billing city
- `billing_state` - Billing state
- `billing_zip` - Billing zip code
- `billing_country` - Billing country
- `shipping_address_line1` - Shipping address line 1
- `shipping_address_line2` - Shipping address line 2
- `shipping_city` - Shipping city
- `shipping_state` - Shipping state
- `shipping_zip` - Shipping zip code
- `shipping_country` - Shipping country

**Example:**
```csv
email,first_name,last_name,phone,shipping_address_line1,shipping_city,shipping_state,shipping_zip,shipping_country
john@example.com,John,Doe,555-1234,123 Main St,Anytown,CA,12345,USA
jane@example.com,Jane,Smith,555-5678,456 Oak Ave,Somewhere,NY,67890,USA
```

**FilaOps Column Mapping:**
FilaOps automatically recognizes many common column name variations:
- `Email`, `E-mail`, `Email Address` → `email`
- `First Name`, `Firstname`, `First Name` → `first_name`
- `Last Name`, `Lastname`, `Last Name` → `last_name`
- `Address 1`, `Address1`, `Street Address` → `billing_address_line1`
- `City` → `billing_city`
- `State`, `Province` → `billing_state`
- `Zip`, `Postcode`, `Postal Code` → `billing_zip`
- `Country` → `billing_country`

---

## Common Issues & Solutions

### Issue: "SKU is required" errors

**Problem:** Some products don't have SKUs in the export.

**Solutions:**
1. **Add SKUs in source platform** before exporting
2. **Generate SKUs** in Excel/Google Sheets:
   - Formula: `=UPPER(SUBSTITUTE(B2," ","-"))&"-"&ROW()`
   - This creates SKUs from product names
3. **Filter out rows** with empty SKUs before importing
4. **Use product ID** as SKU if available

### Issue: "Name is required" errors

**Problem:** Product name column is empty or has different name.

**Solutions:**
1. **Check column names** - FilaOps looks for: `name`, `Name`, `title`, `Title`, `Product Name`
2. **Rename columns** in Excel to match FilaOps format
3. **Fill in missing names** manually
4. **Use product ID** as name if name is missing

### Issue: Price format errors

**Problem:** Prices have $ signs, commas, or other formatting.

**Solutions:**
1. **FilaOps handles this automatically** for most formats
2. **If still errors:**
   - Remove $ signs: `=SUBSTITUTE(A1,"$","")`
   - Remove commas: `=SUBSTITUTE(A1,",","")`
   - Convert to number: `=VALUE(A1)`

### Issue: "Failed to fetch" on customer import

**Problem:** Network error or wrong CSV format.

**Solutions:**
1. **Check CSV format:**
   - Must have `email` column
   - Must be valid CSV (not Excel .xlsx)
   - File size under 10MB
   - No special characters in headers

2. **Check network:**
   - Ensure backend is running
   - Check browser console (F12) for errors
   - Try smaller file first (10-20 rows)

3. **Use preview endpoint:**
   - Use `/api/v1/admin/customers/import/preview` first
   - This validates without importing
   - Shows errors before committing

4. **Check file encoding:**
   - Save as UTF-8 CSV
   - Remove BOM (Byte Order Mark) if present

### Issue: Duplicate emails

**Problem:** Same customer appears multiple times (from orders export).

**Solutions:**
1. **FilaOps automatically skips duplicates** - one customer per email
2. **Or use Excel's "Remove Duplicates"** before importing:
   - Data → Remove Duplicates
   - Select "Email" column
   - Keep most recent row

### Issue: Name not splitting correctly

**Problem:** Full name in one column not splitting into first/last.

**Solutions:**
1. **FilaOps auto-splits** names on first space
2. **If issues:**
   - Split manually in Excel: `=LEFT(A1,FIND(" ",A1)-1)` and `=MID(A1,FIND(" ",A1)+1,100)`
   - Or provide separate `first_name` and `last_name` columns

### Issue: Address fields not mapping

**Problem:** Address columns have different names.

**Solutions:**
1. **FilaOps recognizes many variations:**
   - `Address 1`, `Address1`, `Street Address` → `billing_address_line1`
   - `City` → `billing_city`
   - `State`, `Province` → `billing_state`
   - `Zip`, `Postcode` → `billing_zip`

2. **If still not working:**
   - Rename columns in Excel to match FilaOps format
   - Or use the generic CSV format with exact column names

### Issue: Large file import fails

**Problem:** File too large or times out.

**Solutions:**
1. **Split into smaller files:**
   - Import 100-500 rows at a time
   - Use Excel to split: Filter → Copy → New file

2. **Increase timeout** (if you have backend access):
   - Set `TIMEOUT` environment variable
   - Or increase in server config

3. **Use API directly** for large imports:
   - Use the REST API with smaller batches
   - Or use a script to import programmatically

---

## Quick Reference

### Minimum Product CSV
```csv
sku,name
PROD-001,My Product
PROD-002,Another Product
```

### Minimum Customer CSV
```csv
email
customer@example.com
```

### Full Product CSV
```csv
sku,name,description,selling_price,standard_cost,unit,item_type
PROD-001,Widget,Great widget,19.99,10.00,EA,finished_good
PROD-002,Gadget,Amazing gadget,29.99,15.00,EA,finished_good
```

### Full Customer CSV
```csv
email,first_name,last_name,phone,shipping_address_line1,shipping_city,shipping_state,shipping_zip,shipping_country
john@example.com,John,Doe,555-1234,123 Main St,Anytown,CA,12345,USA
jane@example.com,Jane,Smith,555-5678,456 Oak Ave,Somewhere,NY,67890,USA
```

---

## Tips for Success

1. **Start Small:** Test with 5-10 products/customers first
2. **Check Errors:** Review error messages - they're very specific
3. **Fix in Source:** It's easier to fix data in the source platform before exporting
4. **Use Preview:** Customer import has a preview endpoint to check data first
5. **Backup First:** Always backup your database before large imports
6. **Document Changes:** Keep track of what you imported and when
7. **Validate Data:** Check a few imported records to ensure accuracy

---

## Need Help?

- **Check Error Messages:** They tell you exactly what's wrong
- **Start with Small Test:** Import 5-10 rows to verify format
- **Review Import Results:** They show exactly what was imported vs skipped
- **Check Documentation:** See platform-specific guides above
- **Contact Support:** If you're stuck, reach out for help!

---

**Last Updated:** 2025-12-09

