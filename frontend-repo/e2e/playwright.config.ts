import { defineConfig, devices } from '@playwright/test';

// Acceptance tests are run by the pipeline; only pipeline results count as evidence.
// BASE_URL set  -> tests run against that URL (dev verification, @smoke only).
// BASE_URL unset -> the app is served locally (pull-request validation).
const baseURL = process.env.BASE_URL || 'http://localhost:4200';

export default defineConfig({
  testDir: './acceptance',
  outputDir: '../test-results/e2e/artifacts',
  forbidOnly: !!process.env.CI,
  retries: 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: [
    ['list'],
    ['junit', { outputFile: '../test-results/e2e/junit.xml' }],
    ['html', { outputFolder: '../playwright-report', open: 'never' }],
  ],
  use: {
    baseURL,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: process.env.BASE_URL
    ? undefined
    : {
        command: process.env.E2E_SERVE_COMMAND || 'npm run start -- --port 4200',
        url: baseURL,
        timeout: 240_000,
        reuseExistingServer: !process.env.CI,
      },
});
