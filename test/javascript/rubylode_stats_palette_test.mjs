/* Run with: npm test (Node's own test runner, no extra packages). */
import test from "node:test"
import assert from "node:assert/strict"

// The script is a plain browser script: loaded here, it puts its functions on globalThis as it does on window.
await import("../../assets/javascripts/rubylode_stats_palette.js")
const { resolve, applyTokens, colourConfiguration } = globalThis.RubylodeStatsPalette

const payload = {
  follow_theme: true,
  light: { categorical: ["#L1", "#L2", "#L3"], open: "#LO", closed: "#LC", neutral: "#LN" },
  dark: { categorical: ["#D1", "#D2", "#D3"], open: "#DO", closed: "#DC", neutral: "#DN" }
}

const readerOf = (properties) => (name) => properties[name] || ""

test("without theme properties the plugin palette is used, light or dark", () => {
  assert.deepEqual(resolve(payload, readerOf({}), false).categorical, ["#L1", "#L2", "#L3"])
  assert.equal(resolve(payload, readerOf({}), true).closed, "#DC")
})

test("the theme palette wins when the setting follows the theme and --theme-chart-1 exists", () => {
  const theme = readerOf({ "--theme-chart-1": "#111111", "--theme-chart-2": "#222222", "--theme-chart-4": "#444444" })
  const palette = resolve(payload, theme, false)

  assert.deepEqual(palette.categorical, ["#111111", "#222222", "#444444"])
})

test("theme roles fall back to categorical 1 and 2 and the plugin neutral", () => {
  const theme = readerOf({ "--theme-chart-1": "#111111", "--theme-chart-2": "#222222" })
  const palette = resolve(payload, theme, true)

  assert.equal(palette.open, "#111111")
  assert.equal(palette.closed, "#222222")
  assert.equal(palette.neutral, "#DN")
})

test("theme roles are used when the theme defines them", () => {
  const theme = readerOf({
    "--theme-chart-1": "#111111", "--theme-chart-open": "#0a0a0a", "--theme-chart-closed": "#0b0b0b", "--theme-chart-neutral": "#0c0c0c"
  })
  const palette = resolve(payload, theme, false)

  assert.deepEqual([palette.open, palette.closed, palette.neutral], ["#0a0a0a", "#0b0b0b", "#0c0c0c"])
})

test("a theme with one colour uses it for closed too", () => {
  assert.equal(resolve(payload, readerOf({ "--theme-chart-1": "#111111" }), false).closed, "#111111")
})

test("the theme is ignored when the setting does not follow it", () => {
  const palette = resolve({ ...payload, follow_theme: false }, readerOf({ "--theme-chart-1": "#111111" }), false)

  assert.equal(palette.categorical[0], "#L1")
})

test("reading again after the theme changes gives the new colours", () => {
  const properties = { "--theme-chart-1": "#111111" }
  const read = (name) => properties[name] || ""

  assert.equal(resolve(payload, read, false).categorical[0], "#111111")
  properties["--theme-chart-1"] = "#999999"
  assert.equal(resolve(payload, read, false).categorical[0], "#999999")
})

test("tokens become role colours and wrapping category colours, and other strings stay", () => {
  const palette = { categorical: ["#1", "#2", "#3"], open: "#O", closed: "#C", neutral: "#N" }
  const specification = { scale: { range: ["role:open", "role:closed", "role:neutral", "category:5"] }, title: "role:other", count: 3 }

  assert.deepEqual(applyTokens(specification, palette), { scale: { range: ["#O", "#C", "#N", "#2"] }, title: "role:other", count: 3 })
})

test("the configuration colours single series with the first colour and categories in order", () => {
  const palette = { categorical: ["#1", "#2"], open: "#O", closed: "#C", neutral: "#N" }

  assert.deepEqual(colourConfiguration(palette), { mark: { color: "#1" }, range: { category: ["#1", "#2"] } })
})

test("open status tokens take the palette in order and skip the colour of the closed role", () => {
  const palette = { categorical: ["#1", "#2", "#3", "#4"], open: "#O", closed: "#2", neutral: "#N" }
  const specification = { range: ["open_status:1", "open_status:2", "open_status:3", "open_status:4", "role:closed"] }

  assert.deepEqual(applyTokens(specification, palette).range, ["#1", "#3", "#4", "#1", "#2"])
})
