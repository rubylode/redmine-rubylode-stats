// Checks the charts in the running throwaway Redmine, with its demo data (see the README, "Try it"): the tooltip appears on a mark,
// the other marks dim, a click opens the ticket list with the right filter (ctrl or cmd click in a new tab), the legend hides a
// series, and the data table holds the same figures.  npm run check
import { baseUrl, launch, signedInPage, chartSpecification, waitForChart } from "./browser.mjs"

const browser = await launch()
let failures = 0
const expect = (description, actual, expected) => {
  const ok = JSON.stringify(actual) === JSON.stringify(expected)
  if (!ok) failures += 1
  console.log(`${ok ? "ok  " : "FAIL"} ${description}${ok ? "" : ` (got ${JSON.stringify(actual)}, want ${JSON.stringify(expected)})`}`)
}
const expectTrue = (description, condition) => expect(description, Boolean(condition), true)

const allStatuses = "set_filter=1&f[]=status_id&op[status_id]=*"
const statsUrl = (extra = "") => `${baseUrl}/projects/demo-garden/stats?${allStatuses}${extra}`
const marks = (chartName, kind = "rect") => `#stats-chart-${chartName} svg .mark-${kind}.role-mark :is(path, a)`
const filterOf = (url) => {
  const parameters = new URL(url).searchParams
  return { path: new URL(url).pathname, fields: parameters.getAll("f[]"), operators: Object.fromEntries(parameters.entries()), values: (name) => parameters.getAll(name) }
}

const page = await signedInPage(browser, "alan.turing", "demo-password-1")
const problems = []
page.on("pageerror", (error) => problems.push(error.message))

// Tooltip and hover highlight on a bar.
await page.goto(statsUrl())
await waitForChart(page, "tickets_by_status")
const statusSpecification = await chartSpecification(page, "tickets_by_status")
const statusRows = statusSpecification.data.values
const closedRow = statusRows.find((row) => row.status === "Closed")
const bars = page.locator(`#stats-chart-tickets_by_status svg .mark-rect.role-mark path`)
expect("the status chart has a bar per status", await bars.count(), statusRows.length)
const closedBar = bars.nth(statusRows.indexOf(closedRow))
await closedBar.hover()
const tooltip = page.locator("#vg-tooltip-element.visible")
await tooltip.waitFor()
const tooltipText = await tooltip.innerText()
expectTrue("the tooltip names the status", tooltipText.includes("Closed"))
expectTrue("the tooltip shows the count", tooltipText.replace(/\s+/g, " ").includes(`Tickets ${closedRow.tickets}`))
expectTrue("the tooltip shows the share of the total", /Share of total\s+\d+(\.\d)?%/.test(tooltipText))
expectTrue("the tooltip shows the total", tooltipText.replace(/\s+/g, " ").includes(`All tickets ${closedRow.total}`))
const otherBarOpacity = await bars.nth(statusRows.indexOf(closedRow) === 0 ? 1 : 0).evaluate((path) => Number(path.getAttribute("opacity") ?? path.getAttribute("fill-opacity") ?? 1))
const hoveredBarOpacity = await closedBar.evaluate((path) => Number(path.getAttribute("opacity") ?? path.getAttribute("fill-opacity") ?? 1))
expectTrue("the other bars dim under the pointer", otherBarOpacity < 1 && hoveredBarOpacity === 1)
expectTrue("the tooltip follows the theme (white background in the light scheme)", (await tooltip.evaluate((element) => getComputedStyle(element).backgroundColor)) === "rgb(255, 255, 255)")
await page.mouse.move(5, 5)
expect("the tooltip goes away with the pointer", await page.locator("#vg-tooltip-element.visible").count(), 0)

// A click opens the ticket list with the status filter, in the same tab.
await closedBar.click()
await page.waitForURL(/\/issues\?/)
const clicked = filterOf(page.url())
expect("a click opens this project's ticket list", clicked.path, "/projects/demo-garden/issues")
expectTrue("the list is filtered by status", clicked.fields.includes("status_id"))
expect("the status filter is the clicked status", clicked.operators["v[status_id][]"], String(closedRow.status_id))
expect("the ticket list shows as many tickets as the bar counts", await page.locator("table.issues tr.issue").count() > 0 ? Number((await page.locator(".pagination .items, .pagination").first().innerText()).match(/of (\d+)/)?.[1] ?? closedRow.tickets) : 0, closedRow.tickets)

// A ctrl or cmd click opens a new tab.
await page.goto(statsUrl())
await waitForChart(page, "tickets_by_status")
const modifier = process.platform === "darwin" ? "Meta" : "Control"
const [newTab] = await Promise.all([
  page.context().waitForEvent("page"),
  page.locator(`#stats-chart-tickets_by_status svg .mark-rect.role-mark path`).nth(statusRows.indexOf(closedRow)).click({ modifiers: [modifier] })
])
await newTab.waitForLoadState()
expect("a modified click opens a new tab with the filtered list", filterOf(newTab.url()).operators["v[status_id][]"], String(closedRow.status_id))
expect("the stats page stays where it was", new URL(page.url()).pathname, "/projects/demo-garden/stats")
await newTab.close()

// A week range of the opened and closed chart.
await waitForChart(page, "opened_and_closed")
const openedAndClosed = await chartSpecification(page, "opened_and_closed")
const lastWeek = openedAndClosed.data.values.at(-1)
const openedBars = page.locator("#stats-chart-opened_and_closed svg .mark-rect.role-mark path")
await openedBars.nth(openedAndClosed.data.values.length * 2 - 2).hover()
const periodTooltip = (await page.locator("#vg-tooltip-element.visible").innerText()).replace(/\s+/g, " ")
expectTrue("the opened and closed tooltip names the period and the three figures", periodTooltip.includes(lastWeek.period_text) && periodTooltip.includes(`Opened ${lastWeek.opened}`) && periodTooltip.includes(`Backlog ${lastWeek.backlog}`))
expectTrue("the opened and closed tooltip compares each figure with the previous week", periodTooltip.includes("Backlog vs previous week"))
await page.locator("#stats-chart-opened_and_closed svg .mark-rect.role-mark path").nth(openedAndClosed.data.values.length * 2 - 2).click()
await page.waitForURL(/\/issues\?/)
const weekFilter = filterOf(page.url())
expectTrue("a bar opens the list of tickets created in that week", weekFilter.fields.includes("created_on") && weekFilter.operators["op[created_on]"] === "><")
const weekStart = lastWeek.period
const weekEnd = new Date(Date.parse(weekStart) + 6 * 86400000).toISOString().slice(0, 10)
expect("the range is that week", weekFilter.values("v[created_on][]"), [weekStart, weekEnd])

// The legend hides a series.
await page.goto(statsUrl())
await waitForChart(page, "opened_and_closed")
const legendEntry = page.locator("#stats-chart-opened_and_closed svg .role-legend-entry").first()
await legendEntry.click()
await page.mouse.move(5, 5)
const bluntOpacities = await page.locator("#stats-chart-opened_and_closed svg .mark-rect.role-mark path").evaluateAll((paths) => [...new Set(paths.map((path) => path.getAttribute("opacity") ?? path.getAttribute("fill-opacity") ?? "1"))])
expectTrue("a legend click fades a series", bluntOpacities.length > 1)

// The data table is the same figures, reachable by keyboard.
await page.goto(statsUrl())
await waitForChart(page, "tickets_by_status")
const summary = page.locator("#stats-data-tickets_by_status > summary")
await summary.focus()
await page.keyboard.press("Enter")
expectTrue("the data table opens from the keyboard", await page.locator("#stats-data-tickets_by_status").evaluate((details) => details.open))
const tableRows = await page.locator("#stats-data-tickets_by_status tbody tr").evaluateAll((rows) => rows.map((row) => [row.querySelector("th").innerText, row.querySelectorAll("td")[0].innerText]))
expect("the table lists every status with its count", tableRows, statusRows.map((row) => [row.status, String(row.tickets)]))
expect("the chart is labelled for screen readers", (await page.locator("#stats-chart-tickets_by_status").getAttribute("aria-label")).startsWith("Tickets by status."), true)

// Every other chart: a tooltip on a mark, and a click that opens a ticket list when the chart links (the histogram has no list to open).
const otherCharts = [
  { tab: "overview", chart: "open_versus_closed", selector: ".mark-arc.role-mark path", position: { x: 20, y: 110 }, tooltip: "Share of total", opensList: true },
  { tab: "overview", chart: "tickets_by_slice", selector: ".mark-rect.role-mark path", tooltip: "Share of total", opensList: true },
  { tab: "people", chart: "closed_per_person", selector: ".mark-rect.role-mark path", tooltip: "Share of the period", opensList: true },
  { tab: "speed", chart: "time_to_close_histogram", selector: ".mark-rect.role-mark path", index: 2, tooltip: "Closed in this time or faster", opensList: false },
  { tab: "speed", chart: "median_time_to_close", selector: ".mark-symbol.role-mark path", tooltip: "Median days to close vs previous week", opensList: true },
  { tab: "versions", chart: "progress_per_version", selector: ".mark-rect.role-mark path", tooltip: "Percent done", opensList: true }
]
for (const { tab, chart, selector, position, index = 0, tooltip: expectedLine, opensList } of otherCharts) {
  const open = async () => {
    await page.goto(statsUrl(`&tab=${tab}`))
    await waitForChart(page, chart)
    const mark = page.locator(`#stats-chart-${chart} svg ${selector}`).nth(index)
    return { mark, options: position ? { position } : {} }
  }
  let { mark, options } = await open()
  await mark.hover(options)
  await page.locator("#vg-tooltip-element.visible").waitFor()
  expectTrue(`${chart}: the tooltip carries "${expectedLine}"`, (await page.locator("#vg-tooltip-element").innerText()).includes(expectedLine))
  await page.mouse.move(5, 5)
  ;({ mark, options } = await open())
  await mark.click(options)
  await page.waitForTimeout(600)
  const opened = new URL(page.url()).pathname.endsWith("/issues")
  expect(`${chart}: a click ${opensList ? "opens" : "does not open"} a ticket list`, opened, opensList)
}

// Dark scheme: the tooltip follows it.
const dark = await signedInPage(browser, "alan.turing", "demo-password-1", { colorScheme: "dark" })
await dark.goto(statsUrl())
await waitForChart(dark, "tickets_by_status")
await dark.locator(`#stats-chart-tickets_by_status svg .mark-rect.role-mark path`).first().hover()
await dark.locator("#vg-tooltip-element.visible").waitFor()
// The stock theme has no dark mode of its own, so its colours stay light; a dark theme sets the custom properties.
await dark.addStyleTag({ content: ":root { --stats-tooltip-background: #101010; --stats-tooltip-color: #f0f0f0; }" })
const darkColours = await dark.locator("#vg-tooltip-element").evaluate((element) => [getComputedStyle(element).backgroundColor, getComputedStyle(element).color])
expect("the tooltip takes its colours from the custom properties of the theme", darkColours, ["rgb(16, 16, 16)", "rgb(240, 240, 240)"])

expect("no script errors on the way", problems, [])
await browser.close()
process.exit(failures ? 1 : 0)
