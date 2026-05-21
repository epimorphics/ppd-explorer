import { defineConfig, devices } from '@playwright/test'

const rawBaseURL = process.env['E2E_BASE_URL'] ?? 'http://localhost:3001/'
const baseURL = rawBaseURL.endsWith('/') ? rawBaseURL : `${rawBaseURL}/`

export default defineConfig({
  testDir: 'test/playwright',
  outputDir: 'tmp/test-results',
  reporter: [['html', { outputFolder: 'tmp/playwright-report', open: 'never' }]],
  timeout: 90_000,
  expect: { timeout: 30_000 },

  use: {
    baseURL,
    screenshot: 'only-on-failure',
    ...(process.env['E2E_USERNAME']
      ? {
        httpCredentials: {
          username: process.env['E2E_USERNAME'],
          password: process.env['E2E_PASSWORD'] ?? '',
        },
      }
      : {}),
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  webServer: process.env['E2E_BASE_URL']
    ? undefined
    : {
      command: 'bin/rails server -p 3001',
      url: 'http://localhost:3001',
      reuseExistingServer: true,
      timeout: 60_000,
    },
})
