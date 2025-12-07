import { test as baseTest, expect } from '@playwright/test';

/**
 * Full E2E Workflow Test - WITH SCREENSHOTS
 *
 * Tests navigation through main admin sections
 * Run: npm run test:e2e -- --grep "Full Workflow"
 *
 * Screenshots saved to: e2e/screenshots/
 */

// Custom test with auth
const test = baseTest.extend<{ authenticatedPage: any }>({
  authenticatedPage: async ({ page }, use) => {
    await page.goto('/admin/login');
    await page.fill('input[type="email"]', 'admin@localhost');
    await page.fill('input[type="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL('/admin**', { timeout: 10000 });
    await use(page);
  },
});

// Enable screenshots for this file
test.use({ screenshot: 'on' });

test.describe('Full Workflow E2E', () => {
  test('navigate through admin sections', async ({ authenticatedPage: page }) => {
    const timestamp = Date.now();
    const screenshotDir = `e2e/screenshots/workflow-${timestamp}`;

    // Step 1: After login, we're at /admin
    await page.waitForLoadState('networkidle');
    await page.screenshot({ path: `${screenshotDir}/01-dashboard.png`, fullPage: true });

    // Step 2: Navigate to Orders
    await page.click('text=Orders');
    await expect(page).toHaveURL('/admin/orders');
    await page.waitForLoadState('networkidle');
    await page.screenshot({ path: `${screenshotDir}/02-orders.png`, fullPage: true });

    // Step 3: Navigate to Customers
    await page.click('text=Customers');
    await expect(page).toHaveURL('/admin/customers');
    await page.waitForLoadState('networkidle');
    await page.screenshot({ path: `${screenshotDir}/03-customers.png`, fullPage: true });

    // Step 4: Navigate to Items
    await page.click('text=Items');
    await expect(page).toHaveURL('/admin/items');
    await page.waitForLoadState('networkidle');
    await page.screenshot({ path: `${screenshotDir}/04-items.png`, fullPage: true });

    // Step 5: Navigate to Production
    await page.click('text=Production');
    await expect(page).toHaveURL('/admin/production');
    await page.waitForLoadState('networkidle');
    await page.screenshot({ path: `${screenshotDir}/05-production.png`, fullPage: true });

    // Step 6: Navigate to Bill of Materials
    await page.click('text=Bill of Materials');
    await expect(page).toHaveURL('/admin/bom');
    await page.waitForLoadState('networkidle');
    await page.screenshot({ path: `${screenshotDir}/06-bom.png`, fullPage: true });

    // Step 7: Back to Dashboard
    await page.click('text=Dashboard');
    await expect(page).toHaveURL('/admin');
    await page.waitForLoadState('networkidle');
    await page.screenshot({ path: `${screenshotDir}/07-final-dashboard.png`, fullPage: true });

    console.log(`Screenshots saved to: ${screenshotDir}`);
  });
});
