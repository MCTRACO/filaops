import { Page, expect } from '@playwright/test';
import { E2E_CONFIG } from '../config';

/**
 * Test Utilities for E2E Tests
 *
 * Shared helpers for login, logout, data seeding, and common operations.
 * Use these in test files to maintain consistency across all E2E tests.
 */

// API base URL for test endpoints
const API_BASE_URL = process.env.API_URL || 'http://localhost:8000';

/**
 * Login to the application
 *
 * Note: Most tests should use the auth.setup.ts project dependency instead.
 * Use this only for tests that need to login with different credentials
 * or test the login flow itself.
 *
 * @param page - Playwright page object
 * @param credentials - Optional override credentials
 */
export async function login(
  page: Page,
  credentials?: { email: string; password: string }
): Promise<void> {
  const { email, password } = credentials ?? {
    email: E2E_CONFIG.email,
    password: E2E_CONFIG.password,
  };

  // Navigate to login page
  await page.goto('/admin/login');
  await page.waitForLoadState('networkidle');

  // Fill login form
  await page.fill('input[type="email"]', email);
  await page.fill('input[type="password"]', password);

  // Submit
  await page.click('button[type="submit"]');

  // Wait for redirect away from login
  await page.waitForURL(/\/admin(?!\/login)/, { timeout: 10000 });
}

/**
 * Logout of the application
 */
export async function logout(page: Page): Promise<void> {
  // Click user menu or logout button
  const logoutButton = page.getByRole('button', { name: /logout|sign out/i });

  if (await logoutButton.isVisible().catch(() => false)) {
    await logoutButton.click();
  } else {
    // Try navigating directly
    await page.goto('/admin/login');
    await page.context().clearCookies();
    await page.evaluate(() => localStorage.clear());
  }

  // Verify we're back at login
  await expect(page).toHaveURL(/login/);
}

/**
 * Wait for API calls to complete
 * Useful after actions that trigger backend requests
 */
export async function waitForApi(page: Page): Promise<void> {
  await page.waitForLoadState('networkidle');
}

/**
 * Wait for a specific API response
 */
export async function waitForApiResponse(
  page: Page,
  urlPattern: string | RegExp
): Promise<void> {
  await page.waitForResponse(
    (resp) => {
      if (typeof urlPattern === 'string') {
        return resp.url().includes(urlPattern);
      }
      return urlPattern.test(resp.url());
    },
    { timeout: E2E_CONFIG.defaultTimeout }
  );
}

/**
 * Test scenario types for data seeding
 *
 * These map to backend seeding endpoints that create specific test scenarios.
 * Each scenario sets up the database in a known state for testing.
 */
export type TestScenario =
  | 'empty'                       // Clean slate - just test user
  | 'basic'                       // Basic sample data (users, products, vendors)
  | 'low-stock-with-allocations'  // For demand pegging tests
  | 'production-in-progress'      // Production orders in various states
  | 'production-mto'              // Make-to-order production (alias)
  | 'production-with-shortage'    // Production blocked by materials (alias)
  | 'so-with-blocking-issues'     // Sales order with fulfillment problems
  | 'full-demand-chain'           // Complete SO->WO->PO chain
  | 'full-production-context';    // Complete production with all context (alias)

/**
 * Response from the seed endpoint
 */
export interface SeedResponse {
  success: boolean;
  scenario: string;
  data: Record<string, unknown>;
}

/**
 * Seed test data for a specific scenario
 *
 * Calls the backend seeding endpoint to set up the database
 * in a known state for the given scenario.
 *
 * @param scenario - The test scenario to seed
 * @returns SeedResponse with created object IDs
 * @throws Error if seeding fails
 *
 * @example
 * test('demand pegging', async ({ page }) => {
 *   const result = await seedTestScenario('full-demand-chain');
 *   console.log('Created SO:', result.data.sales_order.order_number);
 *   await login(page);
 *   // ... test with real data
 * });
 */
export async function seedTestScenario(scenario: TestScenario): Promise<SeedResponse> {
  const response = await fetch(`${API_BASE_URL}/api/v1/test/seed`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ scenario }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Failed to seed scenario '${scenario}': ${errorText}`);
  }

  return response.json();
}

/**
 * Clean up test data created during a test
 *
 * Calls the backend cleanup endpoint to remove test data.
 * Use in afterEach hooks to ensure clean state between tests.
 *
 * @example
 * test.afterEach(async () => {
 *   await cleanupTestData();
 * });
 */
export async function cleanupTestData(): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/api/v1/test/cleanup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  });

  if (!response.ok) {
    console.warn('[test-utils] Cleanup failed:', await response.text());
  }
}

/**
 * List available test scenarios from the backend
 *
 * @returns Array of scenario names
 */
export async function listScenarios(): Promise<string[]> {
  const response = await fetch(`${API_BASE_URL}/api/v1/test/scenarios`);
  if (!response.ok) {
    throw new Error('Failed to fetch scenarios');
  }
  const data = await response.json();
  return data.scenarios;
}

/**
 * Navigate to a specific admin page and wait for it to load
 */
export async function navigateTo(
  page: Page,
  path: string
): Promise<void> {
  const fullPath = path.startsWith('/admin') ? path : `/admin${path}`;
  await page.goto(fullPath);
  await page.waitForLoadState('networkidle');
}

/**
 * Take a screenshot with a descriptive name
 * Useful for debugging failed tests
 */
export async function screenshot(
  page: Page,
  name: string
): Promise<void> {
  await page.screenshot({
    path: `./tests/e2e/screenshots/${name}.png`,
    fullPage: true,
  });
}

/**
 * Fill a form field by label
 */
export async function fillField(
  page: Page,
  label: string | RegExp,
  value: string
): Promise<void> {
  await page.getByLabel(label).fill(value);
}

/**
 * Click a button by name
 */
export async function clickButton(
  page: Page,
  name: string | RegExp
): Promise<void> {
  await page.getByRole('button', { name }).click();
}

/**
 * Check if an element with text is visible
 */
export async function isVisible(
  page: Page,
  text: string | RegExp
): Promise<boolean> {
  return page.getByText(text).isVisible().catch(() => false);
}
