import { test as base, Page } from '@playwright/test';

/**
 * Auth fixture - logs in as admin before tests that need authentication
 */
export const test = base.extend<{ authenticatedPage: Page }>({
  authenticatedPage: async ({ page }, use) => {
    // Go to login page
    await page.goto('/admin/login');

    // Fill login form
    await page.fill('input[type="email"]', 'admin@localhost');
    await page.fill('input[type="password"]', 'admin123');
    await page.click('button[type="submit"]');

    // Wait for redirect to admin area
    await page.waitForURL('/admin**', { timeout: 10000 });

    // Use the authenticated page
    await use(page);
  },
});

export { expect } from '@playwright/test';

/**
 * Test data generators
 */
export const testData = {
  customer: {
    email: () => `test-${Date.now()}@example.com`,
    firstName: 'Test',
    lastName: 'Customer',
    company: 'Test Company LLC',
    phone: '555-0100',
  },
  product: {
    sku: () => `TEST-${Date.now()}`,
    name: 'Test Product',
    category: 'Finished Goods',
    sellingPrice: '29.99',
  },
};
