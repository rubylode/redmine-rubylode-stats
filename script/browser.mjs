// Shared helpers for the browser check and the screenshots. Talks only to the throwaway Redmine of this folder (docker compose up -d).
import { chromium } from "playwright-core"
import { existsSync } from "node:fs"

export const baseUrl = process.env.DEMO_URL || "http://localhost:3008"

const chromeCandidates = [
  process.env.CHROME_PATH,
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/usr/bin/google-chrome",
  "/usr/bin/google-chrome-stable",
  "/usr/bin/chromium"
]

export function launch() {
  const executablePath = chromeCandidates.find((candidate) => candidate && existsSync(candidate))
  if (!executablePath) throw new Error("No Chrome found. Set CHROME_PATH to a Chrome or Chromium binary.")
  return chromium.launch({ executablePath, headless: true })
}

export async function signedInPage(browser, login, password, options = {}) {
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 }, colorScheme: "light", ...options })
  const page = await context.newPage()
  await page.goto(`${baseUrl}/login`)
  await page.fill("#username", login)
  await page.fill("#password", password)
  await Promise.all([page.waitForURL((url) => !url.pathname.startsWith("/login")), page.click("#login-submit")])
  return page
}

// The page's own chart rows, read from the specification the server put on the chart's element.
export async function chartSpecification(page, chartName) {
  return page.locator(`#stats-chart-${chartName}`).evaluate((element) => JSON.parse(element.dataset.specification))
}

export async function waitForChart(page, chartName) {
  await page.locator(`#stats-chart-${chartName} svg`).waitFor()
  await page.locator(`#stats-chart-${chartName} svg .mark-rect, #stats-chart-${chartName} svg .mark-arc, #stats-chart-${chartName} svg .mark-symbol`).first().waitFor()
}
