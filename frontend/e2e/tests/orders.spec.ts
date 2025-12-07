import { test, expect } from '../fixtures/auth';

/**
 * Order Management Tests
 * Run: npm run test:e2e -- --grep "orders"
 */
test.describe('Order Management', () => {
  test('should navigate to orders page', async ({ authenticatedPage: page }) => {
    await page.click('text=Orders');
    await expect(page).toHaveURL('/admin/orders');
    await expect(page.locator('h1:has-text("Order Management")')).toBeVisible();
  });

  test('should show orders table', async ({ authenticatedPage: page }) => {
    await page.click('text=Orders');
    await expect(page).toHaveURL('/admin/orders');
    // Wait for table to be visible
    await expect(page.locator('table')).toBeVisible({ timeout: 10000 });
  });

  test('should have create order button', async ({ authenticatedPage: page }) => {
    await page.click('text=Orders');
    await expect(page).toHaveURL('/admin/orders');
    // Check for Create Order button
    await expect(page.locator('button:has-text("Create Order")')).toBeVisible({ timeout: 10000 });
  });

  test('should open create order modal', async ({ authenticatedPage: page }) => {
    await page.click('text=Orders');
    await expect(page).toHaveURL('/admin/orders');
    await page.waitForLoadState('networkidle');

    // Click create button
    await page.click('button:has-text("Create Order")');

    // Modal should appear
    await expect(page.locator('text=Create Sales Order')).toBeVisible({ timeout: 5000 });
  });

  test('should have status filter', async ({ authenticatedPage: page }) => {
    await page.click('text=Orders');
    await expect(page).toHaveURL('/admin/orders');
    await page.waitForLoadState('networkidle');

    // Check for status filter - select with "All Status" text
    await expect(page.locator('select')).toBeVisible({ timeout: 10000 });
  });
});
