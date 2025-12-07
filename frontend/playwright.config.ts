import { defineConfig, devices } from '@playwright/test';

/**
 * FilaOps E2E Test Configuration
 *
 * Run tests: npm run test:e2e
 * Run specific: npm run test:e2e -- --grep "customers"
 * Run with UI: npm run test:e2e -- --ui
 */
export default defineConfig({
  testDir: './e2e/tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',

  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry',
    // No screenshots by default - E2E workflow test enables them explicitly
    screenshot: 'off',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  // Start frontend dev server before tests
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});
