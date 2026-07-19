-- Standalone test runner for the butbicket colorscheme.
-- Run with:  nvim -l tests/run.lua
-- No external dependencies (no plenary/busted); uses only the Neovim Lua API.
-- Exits non-zero on any failure so CI can gate on it.

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path
local contrast = dofile("tests/contrast.lua")

local failures = {}
local function check(ok, msg)
  if ok then
    print("  ok   - " .. msg)
  else
    print("  FAIL - " .. msg)
    table.insert(failures, msg)
  end
end

-- Fresh palette for the current `vim.o.background`.
local function palette()
  package.loaded["butbicket.colorscheme"] = nil
  return require("butbicket.colorscheme")
end

-- Palette keys every highlight relies on. If any is nil, groups silently lose
-- their color (this is exactly the class of bug find-replace corruption causes).
local required_keys = {
  "editorBackground",
  "mainText",
  "emphasisText",
  "commentText",
  "lineNumberText",
  "syntaxFunction",
  "syntaxKeyword",
  "syntaxError",
  "syntaxOperator",
  "syntaxNumber",
  "stringText",
  "linkText",
  "errorText",
  "warningText",
  "successText",
  "specialKeyword",
  "windowBorder",
  "floatBorder",
}

-- fg-on-bg pairs to grade. Comments are intentionally low-contrast, so they get
-- a gentler floor. Everything else is body-legible syntax.
local function contrast_pairs(c)
  return {
    { name = "mainText", fg = c.mainText, floor = 4.5 },
    { name = "commentText", fg = c.commentText, floor = 2.5 },
    { name = "stringText", fg = c.stringText, floor = 3.0 },
    { name = "syntaxKeyword", fg = c.syntaxKeyword, floor = 3.0 },
    { name = "syntaxFunction", fg = c.syntaxFunction, floor = 3.0 },
    { name = "linkText", fg = c.linkText, floor = 3.0 },
    { name = "errorText", fg = c.errorText, floor = 3.0 },
    { name = "warningText", fg = c.warningText, floor = 3.0 },
    { name = "successText", fg = c.successText, floor = 3.0 },
    -- raw palette keys used directly as foreground by hl-groups.lua
    { name = "type", fg = c.type, floor = 3.0 },
    { name = "method", fg = c.method, floor = 3.0 },
    { name = "keyword", fg = c.keyword, floor = 3.0 },
    { name = "number", fg = c.number, floor = 3.0 },
    { name = "variable", fg = c.variable, floor = 3.0 },
    { name = "parameter", fg = c.parameter, floor = 3.0 },
    { name = "text_dark", fg = c.text_dark, floor = 4.5 },
  }
end

for _, bg in ipairs({ "dark", "light" }) do
  print("\n== background=" .. bg .. " ==")
  vim.o.background = bg

  -- 1. loads without error
  local ok, err = pcall(function()
    require("butbicket").colorscheme()
  end)
  check(ok, "colorscheme() loads (" .. bg .. ")")
  if not ok then
    print("       " .. tostring(err))
  end

  -- 2. no nil in required palette keys
  local c = palette()
  for _, key in ipairs(required_keys) do
    check(c[key] ~= nil, "palette." .. key .. " is defined")
  end

  -- 3. contrast grading against the editor background
  local editor_bg = c.editorBackground
  if editor_bg == "none" then
    editor_bg = bg == "light" and "#ffffff" or "#101214"
  end
  for _, pair in ipairs(contrast_pairs(c)) do
    if pair.fg then
      local r = contrast.ratio(pair.fg, editor_bg)
      check(
        r >= pair.floor,
        string.format(
          "%-16s %s on %s = %.2f (floor %.1f)",
          pair.name,
          pair.fg,
          editor_bg,
          r,
          pair.floor
        )
      )
    end
  end
end

-- OKLab math: hex -> OKLch -> hex must round-trip within 1/255 per channel.
-- Guards the conversion module the palette tooling (flavour, light preview)
-- depends on.
print("\n== oklab round-trip ==")
do
  local oklab = require("butbicket.oklab")
  local function channels(hex)
    return tonumber(hex:sub(2, 3), 16),
      tonumber(hex:sub(4, 5), 16),
      tonumber(hex:sub(6, 7), 16)
  end
  local samples = {
    "#ffffff",
    "#000000",
    "#101214",
    "#fd9891",
    "#7ee2b8",
    "#8fb8f6",
    "#fbc828",
    "#669cf0",
    "#e78178",
    "#bf63f3",
    "#73a130",
    "#ba9420",
  }
  for _, hex in ipairs(samples) do
    local rt = oklab.oklch_to_hex(oklab.hex_to_oklch(hex))
    local r1, g1, b1 = channels(hex)
    local r2, g2, b2 = channels(rt)
    local d = math.max(math.abs(r1 - r2), math.abs(g1 - g2), math.abs(b1 - b2))
    check(d <= 1, string.format("round-trip %s -> %s (Δ%d)", hex, rt, d))
  end
end

-- Flavour generator: a re-toned palette preserves every semantic key and its
-- syntax foregrounds still clear their floor on the new background.
print("\n== flavour generator ==")
do
  vim.o.background = "dark"
  package.loaded["butbicket.colorscheme"] = nil
  local canonical = require("butbicket.colorscheme")
  local flavour = require("butbicket.flavour")

  local p = flavour.generate(canonical, {
    background = "#0d1b2a",
    foreground = "#e2e8f4",
    hue_shift = -8,
  })

  for _, key in ipairs(required_keys) do
    check(p[key] ~= nil, "flavour keeps palette." .. key)
  end

  local bg = p.editorBackground
  for _, pair in ipairs(contrast_pairs(p)) do
    if pair.fg then
      local r = contrast.ratio(pair.fg, bg)
      check(
        r >= pair.floor,
        string.format(
          "flavour %-14s %.2f (floor %.1f)",
          pair.name,
          r,
          pair.floor
        )
      )
    end
  end

  -- n_hues + accents: accents pin a role, semantic-meaning colors stay locked.
  local oklab = require("butbicket.oklab")
  local plain = flavour.generate(canonical, {
    background = "#101214",
    foreground = "#e7e7e8",
  })
  local hued = flavour.generate_hues(canonical, {
    background = "#101214",
    foreground = "#e7e7e8",
    n_hues = 3,
    accents = { keyword = "#c678dd" },
  })
  local function hue(hex)
    return oklab.hex_to_oklch(hex).h or 0
  end
  local function circ(a, b)
    local d = math.abs((a - b) % 360)
    return math.min(d, 360 - d)
  end
  check(
    circ(hue(hued.syntaxKeyword), hue("#c678dd")) < 3,
    "accents pin keyword hue to the requested color"
  )
  check(
    hued.errorText == plain.errorText,
    "n_hues leaves semantic errorText locked"
  )
  check(
    hued.successText == plain.successText,
    "n_hues leaves semantic successText locked"
  )
  check(hued.editorBackground ~= nil, "generate_hues keeps a complete palette")
end

-- Integration registry: every module loads and returns a highlight table, and
-- the enable/detect gating behaves.
print("\n== integrations ==")
do
  vim.o.background = "dark"
  package.loaded["butbicket.colorscheme"] = nil
  package.loaded["butbicket.integrations"] = nil
  local I = require("butbicket.integrations")
  local cfg = { transparent = false, italics = { bufferline = false } }

  for _, spec in ipairs(I.registry) do
    local ok, hl = pcall(function()
      local mod = require("butbicket.integrations." .. spec.module)
      return spec.wants_config and mod.highlights(cfg) or mod.highlights()
    end)
    check(
      ok and type(hl) == "table",
      "integration " .. spec.name .. " highlights() returns a table"
    )
  end

  -- Gating: nothing is emitted when no plugin is installed / all disabled.
  check(
    next(I.highlights({ integrations = { default = false } })) == nil,
    "default=false emits no groups"
  )
  check(
    next(I.highlights({ integrations = { default = true } })) == nil,
    "no installed plugins emits no groups"
  )
end

print("")
if #failures > 0 then
  print(("%d check(s) failed"):format(#failures))
  os.exit(1)
end
print("all checks passed")
