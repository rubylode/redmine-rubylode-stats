// Retakes the README screenshots from the throwaway Redmine with its fake demo data (see the README, "Try it").  npm run screenshots
import { baseUrl, launch, signedInPage, waitForChart } from "./browser.mjs"

const browser = await launch()
const page = await signedInPage(browser, "alan.turing", "demo-password-1", { viewport: { width: 1400, height: 900 } })
const outputFolder = new URL("../docs/screenshots/", import.meta.url).pathname
const allStatuses = "set_filter=1&f[]=status_id&op[status_id]=*"

async function shoot(name, path, chartNames, { fullPage = false } = {}) {
  await page.goto(`${baseUrl}${path}`)
  for (const chartName of chartNames) await waitForChart(page, chartName)
  await page.mouse.move(2, 2)
  await page.screenshot({ path: `${outputFolder}${name}.png`, fullPage })
  console.log(`took ${name}`)
}

await shoot("stats-overview", `/projects/demo-garden/stats?${allStatuses}`, ["tickets_by_status", "opened_and_closed"], { fullPage: true })
await shoot("stats-people", `/projects/demo-garden/stats?${allStatuses}&tab=people`, ["closed_per_person"])
await shoot("stats-speed", `/projects/demo-garden/stats?${allStatuses}&tab=speed`, ["time_to_close_histogram", "median_time_to_close"])
await shoot("stats-versions", `/projects/demo-garden/stats?${allStatuses}&tab=versions`, ["progress_per_version"])
await shoot("stats-all-projects", `/stats?${allStatuses}`, ["tickets_by_status", "opened_and_closed"], { fullPage: true })

// The tooltip: the pointer on one week of the opened and closed chart, the other weeks dimmed.
await page.goto(`${baseUrl}/projects/demo-garden/stats?${allStatuses}`)
await waitForChart(page, "opened_and_closed")
const card = page.locator("#stats-card-opened_and_closed")
await card.scrollIntoViewIfNeeded()
await page.locator("#stats-chart-opened_and_closed svg .mark-rect.role-mark path").nth(20).hover()
await page.locator("#vg-tooltip-element.visible").waitFor()
const box = await card.boundingBox()
await page.screenshot({ path: `${outputFolder}stats-tooltip.png`, clip: { x: box.x - 8, y: box.y - 8, width: box.width + 16, height: box.height + 16 } })
console.log("took stats-tooltip")

await browser.close()
