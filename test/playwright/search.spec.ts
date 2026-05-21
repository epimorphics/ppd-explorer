import { test, expect, type Page } from '@playwright/test'

test.beforeEach(async ({ page }) => {
  await page.goto('./')
})

async function submitSearch(page: Page) {
  await page.getByRole('button', { name: /show results/i }).click()
  await expect(page.locator('.search-summary')).toBeVisible()
}

const summary = (page: Page) => page.locator('.search-summary')
const firstAddress = (page: Page) => page.locator('.ppd-results .address').first()

test.describe('Building search', () => {
  test('finds properties by building name', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(summary(page)).toContainText(/propert/)
    await expect(firstAddress(page)).toContainText('Rose Cottage')
  })
})

test.describe('Street search', () => {
  test('finds properties by street', async ({ page }) => {
    await page.getByLabel('Street').fill('Harbour Road')
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(firstAddress(page)).toContainText('Harbour Road')
  })
})

test.describe('Town search', () => {
  test('finds properties by town', async ({ page }) => {
    await page.getByLabel('Town or city').fill('Plymouth')
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(summary(page)).toContainText(/propert/)
    await expect(firstAddress(page)).toContainText('Plymouth')
  })
})

test.describe('District search', () => {
  test('finds properties by district', async ({ page }) => {
    await page.getByLabel('District').fill('City of Westminster')
    await page.getByLabel('at most 1000').check()
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(summary(page)).toContainText(/propert/)
    await expect(firstAddress(page)).toBeVisible()
  })
})

test.describe('County search', () => {
  test('finds properties by county', async ({ page }) => {
    await page.getByLabel('County').fill('Devon')
    await page.getByLabel('at most 100', { exact: true }).check()
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(summary(page)).toContainText(/propert/)
    await expect(firstAddress(page)).toBeVisible()
  })
})

test.describe('Locality search', () => {
  test('finds properties by locality', async ({ page }) => {
    await page.getByLabel('Locality').fill('Thurloxton')
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(firstAddress(page)).toBeVisible()
  })
})

test.describe('Postcode search', () => {
  test('finds properties by postcode', async ({ page }) => {
    await page.getByLabel('Postcode').fill('PL6')
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(summary(page)).toContainText(/propert/)
    await expect(firstAddress(page)).toContainText('PL6')
  })
})

test.describe('Property type filter', () => {
  test('filters by property type', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('detached', { exact: true }).uncheck()
    await page.getByLabel('semi-detached', { exact: true }).uncheck()
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(firstAddress(page)).toContainText('Rose Cottage')
  })
})

test.describe('New build filter', () => {
  test('filters to new builds only', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('not new-build').uncheck()
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(firstAddress(page)).toContainText('Rose Cottage')
  })
})

test.describe('Estate type filter', () => {
  test('filters by estate type', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('leasehold').uncheck()
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(firstAddress(page)).toContainText('Rose Cottage')
  })
})

test.describe('Transaction category filter', () => {
  test('filters by transaction category', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('standard').uncheck()
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(firstAddress(page)).toContainText('Rose Cottage')
  })
})

test.describe('Price range filter', () => {
  test('filters by price range', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('Minimum price').fill('0')
    await page.getByLabel('Maximum price').fill('200000')
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(firstAddress(page)).toContainText('Rose Cottage')
  })
})

test.describe('Date range filter', () => {
  test('filters by date range', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('Earliest').fill('2020-11-22')
    await page.getByLabel('Latest').fill('2021-11-22')
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(firstAddress(page)).toContainText('Rose Cottage')
  })

  test('returns zero results when earliest date is after latest date', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('Earliest').fill('2021-11-22')
    await page.getByLabel('Latest').fill('2020-11-22')
    await submitSearch(page)
    await expect(summary(page)).toContainText('0 transactions')
  })
})

test.describe('Results limit', () => {
  test('limits results to 1000', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('at most 1000').check()
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(summary(page)).toContainText(/propert/)
    await expect(firstAddress(page)).toContainText('Rose Cottage')
  })

  test('shows a warning when all results are requested', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('all').check()
    await submitSearch(page)
    await expect(page.locator('.search-limit-reached')).toContainText('We have limited this page to 5000 results')
    await expect(firstAddress(page)).toContainText('Rose Cottage')
  })
})

test.describe('Large queries', () => {
  test('handles large result sets', async ({ page }) => {
    test.slow()
    await page.getByLabel('Town or city').fill('Birmingham')
    await page.getByLabel('all').check()
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(summary(page)).toContainText(/propert/)
    await expect(page.locator('.search-limit-reached')).toContainText('We have limited this page to 5000 results')
    await expect(firstAddress(page)).toBeVisible()
  })
})

test.describe('Special character handling', () => {
  test('searches containing & return results correctly', async ({ page }) => {
    await page.getByLabel('Street').fill('adam and eve mews')
    await submitSearch(page)
    await expect(summary(page)).toContainText(/transaction/)
    await expect(firstAddress(page)).toContainText('Mews')
  })
})

test.describe('Help', () => {
  test('opens and closes the help modal', async ({ page }) => {
    await page.locator('.action-help').first().click()
    await expect(page.locator('#help-modal')).toBeVisible()
    await expect(page.locator('#help-modal .trouble-shooting')).toBeVisible()
    await page.locator('#help-modal button.close').click()
    await expect(page.locator('#help-modal')).not.toBeVisible()
  })
})

test.describe('Reset form', () => {
  test('clears all entered values', async ({ page }) => {
    await page.getByLabel('Building name or number').fill('Rose Cottage')
    await page.getByLabel('Locality').fill('Thurloxton')
    await page.getByRole('link', { name: /reset the form/i }).first().click()
    await expect(page.getByLabel('Building name or number')).toHaveValue('')
    await expect(page.getByLabel('Locality')).toHaveValue('')
  })
})
