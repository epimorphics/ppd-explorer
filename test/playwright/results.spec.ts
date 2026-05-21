import { test, expect, type Page } from '@playwright/test'

test.beforeEach(async ({ page }) => {
  await page.goto('./')
})

async function submitSearch (page: Page) {
  await Promise.all([
    page.waitForURL(/\/search/, { timeout: 90_000 }),
    page.getByRole('button', { name: /show results/i }).click(),
  ])
}

const summary = (page: Page) => page.locator('.search-summary')
const firstResult = (page: Page) => page.locator('.ppd-results li').first()

test.describe('Deselect search queries', () => {
  test('removing a search term re-renders results', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('Town or city').fill('Plymouth')
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)

    await page.locator('.search-terms li')
      .filter({ hasText: /Plymouth/i })
      .locator('.search-term')
      .click()

    await expect(page.locator('.search-summary')).toBeVisible()
    await expect(summary(page)).toContainText(/transaction/)
  })
})

test.describe('Change settings', () => {
  test('returns to the search form with values preserved', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await submitSearch(page)
    await page.getByRole('link', { name: /change search settings/i }).first().click()
    await expect(page.getByLabel('Building name or number')).toHaveValue('Rose Cottage')
  })
})

test.describe('Download data', () => {
  test('navigates to the download page, offers CSV and Turtle, returns to results', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await submitSearch(page)

    await page.getByRole('link', { name: /download data/i }).first().click()
    await expect(page).toHaveURL(/ppd_data/)

    const [download] = await Promise.all([
      page.waitForEvent('download'),
      page.getByRole('link', { name: /get selected results as csv/i }).first().click(),
    ])
    expect(download.suggestedFilename()).toMatch(/\.csv$/)

    const ttlHref = await page.getByRole('link', { name: /get selected results as turtle/i }).first().getAttribute('href')
    expect(ttlHref).toMatch(/ttl/)

    await page.getByRole('link', { name: /back to results/i }).click()
    await expect(page.locator('.search-summary')).toBeVisible()
  })
})

test.describe('Share', () => {
  test('opens and closes the share modal', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await submitSearch(page)
    await page.locator('.action-bookmark').first().click()
    await expect(page.locator('#bookmark-modal')).toBeVisible()
    await page.locator('#bookmark-modal button.close').click()
    await expect(page.locator('#bookmark-modal')).toBeHidden()
  })
})

test.describe('Results summary number displayed', () => {
  test('switching result limit re-renders with updated selection', async ({ page }) => {
    test.slow()
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)

    await Promise.all([
      page.waitForURL(/\/search/, { timeout: 90_000 }),
      page.getByRole('link', { name: /show a sample of at most 1000 results/i }).click(),
    ])
    await expect(summary(page)).toContainText(/transaction/)

    await Promise.all([
      page.waitForURL(/\/search/, { timeout: 90_000 }),
      page.getByRole('link', { name: /show all results/i }).click(),
    ])
    await expect(page.locator('.search-selection')).toContainText(/show all results/i)
  })
})

test.describe('Results list item', () => {
  test('each result has an address, transaction history, and detailed address', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await submitSearch(page)

    await expect(firstResult(page).locator('.property-heading .address')).toBeVisible()
    await expect(firstResult(page).locator('.transaction-history tbody tr').first()).toBeVisible()
    await expect(firstResult(page).locator('a[aria-label="show transaction raw data"]')).toBeVisible()
    await expect(firstResult(page).locator('.detailed-address')).toBeVisible()
  })
})

test.describe('Results list query within', () => {
  test('clicking a district filter re-renders results scoped to that district', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('County').fill('Devon')
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)

    await page.locator('[aria-label="add a filter for district"]').first().click()
    await expect(page.locator('.search-summary')).toBeVisible()
    await expect(page.locator('.search-terms')).toContainText(/district/i)
    await expect(summary(page)).toContainText(/transaction/)
  })
})

test.describe('PPD datasets page', () => {
  test('static datasets page loads with correct title and content', {
    annotation: {
      type: 'issue',
      description: 'https://github.com/epimorphics/ppd-explorer/issues/335',
    },
  }, async ({ page }) => {
    test.fixme()
    const origin = new URL(page.url()).origin
    await page.goto(`${origin}/ppd-data.html`)
    await expect(page).toHaveTitle(/Download Price Paid Data/i)
    await expect(page.locator('body')).toContainText('Price paid data download options')
  })
})
