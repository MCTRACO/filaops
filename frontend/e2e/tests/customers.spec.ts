import { test, expect } from '../fixtures/auth';

/**
 * Customer Management Tests
 * Run: npm run test:e2e -- --grep "customers"
 */
test.describe('Customer Management', () => {
  test('should navigate to customers page', async ({ authenticatedPage: page }) => {
    await page.click('text=Customers');
    await expect(page).toHaveURL('/admin/customers');
    await expect(page.locator('h1:has-text("Customers")')).toBeVisible();
  });

  test('should show customer table', async ({ authenticatedPage: page }) => {
    await page.click('text=Customers');
    await expect(page).toHaveURL('/admin/customers');
    // Wait for table to be visible
    await expect(page.locator('table')).toBeVisible({ timeout: 10000 });
  });

  test('should have add customer button', async ({ authenticatedPage: page }) => {
    await page.click('text=Customers');
    await expect(page).toHaveURL('/admin/customers');
    // Check for Add Customer button
    await expect(page.locator('button:has-text("Add Customer")')).toBeVisible({ timeout: 10000 });
  });

  test('should view customer details if customers exist', async ({ authenticatedPage: page }) => {
    await page.click('text=Customers');
    await expect(page).toHaveURL('/admin/customers');
    await page.waitForLoadState('networkidle');

    // Check if there are any View buttons in the table
    const viewButtons = page.locator('tbody button:has-text("View")');
    const count = await viewButtons.count();

    if (count > 0) {
      await viewButtons.first().click();
      // Modal should appear - check for Close button (always present)
      await expect(page.locator('button:has-text("Close")')).toBeVisible({ timeout: 5000 });
    }
  });
});
